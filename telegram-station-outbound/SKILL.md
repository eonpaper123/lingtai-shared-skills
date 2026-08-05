---
name: telegram-station-outbound
description: >
  Safe Telegram reaction/reply fallback when an `mcp.telegram` notification arrives but no
  dedicated Telegram action exists, plus the stored-message branch for reacting to an Agent's own
  pre-molt notice after recovery. Applies 👀 only after actual live-turn reading, uses Rawle's latest
  direct base-👌 recovery semantics, uses the existing local secret without exposing it, repairs a
  missing Agent-open 👀 when necessary, and never provisions credentials or sends documents.
version: 1.4.0
last_changed_at: "2026-08-04T23:45:00+08:00"
tags: [powershell, telegram, workflow, security]
---

# Telegram station outbound fallback

## When this applies

Use this procedure only when all are true:

1. Either the source event is an `mcp.telegram` notification, or a recovered `telegram-molt-lifecycle` receipt identifies the exact Agent-authored pre-molt notice message that now needs its authorized recovery reaction.
2. The agent has no dedicated Telegram producer action.
3. Live capabilities include `shell`.
4. `.secrets/telegram.json` already exists and belongs to this station bot.
5. The requested reaction/reply is authorized by the incoming human message, the persisted lifecycle receipt, or standing channel policy.

Prefer a real Telegram producer tool when one exists. This is a station fallback, not an MCP installer and not a credential-provisioning procedure. It uses structured plain text when rich support is unproven. After station-specific `parse_mode` proof and caller-owned escaping, ordinary non-trivial messages may use lightweight HTML text (for example one bold heading plus bullets); that does not imply a standalone HTML artifact. A successful send proves transport, never human-visible rendering.

## Non-negotiable security rules

- Never print the credential, the credential-bearing Bot API URI, the secret JSON body, or a command line containing the credential.
- Never copy a credential into a prompt, email, report, task card, skill, Pad, Knowledge, or log.
- Build the secret property name dynamically (`'bot_' + 'token'`). A direct property reference can be replaced by a secret redactor and fail as a literal placeholder.
- If a human pastes a new credential into chat, treat it as exposed. Do **not** call, validate, persist, or deploy it. React/acknowledge, ask for immediate BotFather revoke/regenerate, and request secure local secret-store injection. A private chat is still message history and may be mirrored into notifications/logs.
- Do not modify project code. Agent or bot configuration changes require separate authorization and the exact addon/secret manual.
- This procedure does **not** send documents (no media/document support) and does **not** provision credentials.

## Procedure

### 1. Anchor the source message

Read the producer notification and record only non-secret routing data:

- `chat_id`
- original Telegram `message_id`
- the reply text you intend to send

If the notification is truncated, ambiguous, or contains a credential, stop and apply the security rules above.

### 2. Read the shell manual

Load `shell-manual` before running the command. Use one short synchronous PowerShell command. Check `exit_code`, `ok`, `warning`, `stdout`, and `stderr`; top-level tool status alone is not proof.

### 3. Load the existing credential without displaying it

```powershell
$cfg = Get-Content -Raw '.secrets\telegram.json' | ConvertFrom-Json
$acct = if ($cfg.accounts) { @($cfg.accounts)[0] } else { $cfg }
$secretField = 'bot_' + 'token'
$token = $acct.PSObject.Properties[$secretField].Value
if ([string]::IsNullOrWhiteSpace($token)) { throw 'Telegram token field missing' }
$base = 'https://api.telegram.org/bot' + $token
```

Do not output `$token` or `$base`.

### 4. Repair a missing Agent-open receipt when necessary

The station runtime applies 👀 only after successful delivery, when the message enters
the Agent's current turn and is opened. It must not react at raw polling or queueing.
If the open-time hook fails, the Agent applies 👀 as its first action and reports the
fallback. An existing Agent-open 👀 is valid and should not be removed or repeated.

```powershell
$reactionBody = @{
  chat_id = '<CHAT_ID>'
  message_id = <MESSAGE_ID>
  reaction = @(@{ type = 'emoji'; emoji = '👀' })
} | ConvertTo-Json -Depth 5 -Compress

$reaction = Invoke-RestMethod -Method Post `
  -Uri ($base + '/setMessageReaction') `
  -ContentType 'application/json' `
  -Body $reactionBody
```

### 5. Reply on Telegram (plain, default)

```powershell
$parseModeUsed = 'plain'
$reply = Invoke-RestMethod -Method Post `
  -Uri ($base + '/sendMessage') `
  -ContentType 'application/json' `
  -Body (@{ chat_id = '<CHAT_ID>'; text = '<REPLY_TEXT>' } | ConvertTo-Json -Compress)
```

### 5a. Optional controlled HTML reply (opt-in only)

Use `parse_mode='HTML'` only when **all** hold:

1. The send path actually carries `parse_mode` to the Bot API (this station's wrapper may not support it — if it cannot, stay plain);
2. The caller explicitly opts in and owns escaping: every dynamic value — user text, names, paths, errors, generated values — is escaped for HTML text nodes (`&` → `&amp;` before `<` → `&lt;` and `>` → `&gt;`, quotes only inside attributes, prefer no dynamic attributes). Use the `telegram-readable-delivery` skill / its `escape_html.py`;
3. The message uses the controlled subset (`<b>`, `<i>` sparingly, `<code>`, short `<pre>`, reviewed `<a href>`), with no tables, colours, or inbound markup.

```powershell
$parseModeUsed = 'HTML'
$reply = Invoke-RestMethod -Method Post `
  -Uri ($base + '/sendMessage') `
  -ContentType 'application/json' `
  -Body (@{
    chat_id = '<CHAT_ID>'
    text = '<CALLER_ESCAPED_HTML_TEXT>'
    parse_mode = 'HTML'
  } | ConvertTo-Json -Compress)
```

Parse-error correction (exactly once): if the API returns a 400 "can't parse entities" style error, identify the single escaping/template defect (usually an unescaped `&`, `<`, `>` or a stray quote in an attribute), correct it, and retry once. If it still fails, resend the same content as plain text without `parse_mode` and report the fallback. Do not blindly retry an ambiguous send; first determine whether the message already arrived.

### 6. Return only safe evidence

```powershell
$entities = @($reply.result.entities)
[pscustomobject]@{
  reaction_ok = $reaction.ok
  reply_ok = $reply.ok
  reply_message_id = $reply.result.message_id
  parse_mode_used = $parseModeUsed
  entity_count = $entities.Count
  entity_types = @($entities | ForEach-Object { $_.type } | Sort-Object -Unique)
} | ConvertTo-Json -Compress
```

`entity_count`/`entity_types` are transport-level facts returned by the API when formatting was parsed; they are **not** proof that a human saw legible rich output.

### 7. Clear only after successful handling

After both reaction and reply succeed, call:

```text
notification(action='dismiss_channel',
             input={'channel': 'mcp.telegram', 'force': null,
                    'reason': 'continue: reacted and replied; message_id=<new id>'},
             reasoning='clear the handled Telegram notification')
```

If dismissal is guarded or fails, do not force it merely to make the queue look clean. Preserve the notification and report the exact error.

### 8. Report evidence

Report these facts to the coordinating agent:

- original message id
- evidence that the reaction call occurred only after the Agent received and read the message in its live turn
- reaction success from that Agent-initiated call (not an ingress reaction)
- new reply message id
- parse mode used (plain or HTML) and, for HTML, `entity_count`/`entity_types`
- notification dismissal result
- live model/state when recovery verification is part of the task
- transport vs visual: a successful API call proves transport only. Do **not** claim "rendered/rich delivery" without a designated verifier's visual confirmation in an approved route; otherwise say "sent, transport verified; visual confirmation pending".
- confirmation that no credential, credential-bearing URI, project code, or unapproved config was printed/changed

## Molt lifecycle stored-message branch

Read `telegram-molt-lifecycle` first. This branch is for a recovered Agent that has an exact, durable receipt for its own pre-molt Telegram notice; it is not permission to react to a vaguely matched historical message.

1. Load only the non-secret `account`, `chat_id`, `message_id`, send timestamp, and requested recovery reaction from the persisted lifecycle block.
2. Verify the account still maps to this station's existing `.secrets/telegram.json`; never copy a credential across bots.
3. Use the same secret-loading pattern above. Build `setMessageReaction` for the exact stored `chat_id`/`message_id` and use Rawle's latest requested base emoji `👌` directly.
4. If Telegram returns a typed 400/invalid-reaction rejection for base `👌`, preserve that one failure receipt and report the lifecycle acknowledgement as blocked; do not guess or retry an alternate emoji.
5. Return safe evidence: stored notice message ID, exact accepted emoji (when accepted), reaction success, recovery reply message ID, and actual elapsed recovery time. Never output the token, base URI, or secret JSON.
6. Mark the durable lifecycle receipt complete only after the reaction/reply result is known.

This is a lifecycle-completion reaction, not the ordinary Agent-open receipt. Do not use `👌` as a substitute for 👀 on Rawle's incoming message.

## Failure branches

- **No `shell` capability:** ask the config owner to repair the canonical capability surface; do not guess an MCP registration.
- **No secret file / missing field:** report the missing local secret path. Do not ask the human to paste a credential into chat.
- **401/unauthorized:** treat the stored credential as invalid or revoked; request secure rotation.
- **Reaction fails but send succeeds:** report partial completion; do not claim full handling.
- **Parse error on HTML send:** apply the single diagnosed correction, retry once, then plain-text fallback (see 5a); never loop retries.
- **HTML requested but the wrapper cannot carry `parse_mode`:** stay on the plain path and report rich delivery unavailable on this station.
- **Human pasted credential:** acknowledge the message with the existing bot if possible, warn the human to revoke/regenerate, leave configuration untouched, and keep the task pending until secure local injection is confirmed.

## Network hard rules (Rawle :249/:279 — 2026-08-05, control-total propagated)
- 👀 read receipt is the FIRST action when you open a Rawle Telegram message: manually react 👀 via your own .secrets/telegram.json + curl setMessageReaction (auto-hook may fail; never skip).
- Self-check: read your .status.json each turn; if active_turn.elapsed_seconds > 600 you are stuck — recover (kill escaped child trees / taskkill /T /F) or ask control-total; do not sit silent.
- Long CLI children (opencode/codex/claude) can escape shell timeouts on Windows and wedge the turn; use async+poll or bounded process-tree-safe runs.
- Control-total runs a 5-min stuck-agent watchdog (task LingTai_StuckAgentWatchdog) and will interrupt/restart stuck agents.
