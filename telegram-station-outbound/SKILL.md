---
name: telegram-station-outbound
description: >
  Safe Telegram reaction/reply fallback for LingTai station agents whose station bridge delivers
  `mcp.telegram` notifications but whose active tool surface has no dedicated Telegram action.
  Uses an existing local `.secrets/telegram.json` through PowerShell shell without revealing the
  bot credential, then clears the handled notification. Do not use this skill to provision a new
  credential, and never use a credential pasted into chat; rotate exposed values first.
version: 1.0.0
last_changed_at: "2026-08-04T16:22:20+08:00"
tags: [powershell, telegram, workflow, security]
---

# Telegram station outbound fallback

## When this applies

Use this procedure only when all are true:

1. The source event is an `mcp.telegram` notification.
2. The agent has no dedicated Telegram producer action.
3. Live capabilities include `shell`.
4. `.secrets/telegram.json` already exists and belongs to this station bot.
5. The requested reaction/reply is authorized by the incoming human message or standing channel policy.

Prefer a real Telegram producer tool when one exists. This is a station fallback, not an MCP installer and not a credential-provisioning procedure.

## Non-negotiable security rules

- Never print the credential, the credential-bearing Bot API URI, the secret JSON body, or a command line containing the credential.
- Never copy a credential into a prompt, email, report, task card, skill, Pad, Knowledge, or log.
- Build the secret property name dynamically (`'bot_' + 'token'`). A direct property reference can be replaced by a secret redactor and fail as a literal placeholder.
- If a human pastes a new credential into chat, treat it as exposed. Do **not** call, validate, persist, or deploy it. React/acknowledge, ask for immediate BotFather revoke/regenerate, and request secure local secret-store injection. A private chat is still message history and may be mirrored into notifications/logs.
- Do not modify project code. Agent or bot configuration changes require separate authorization and the exact addon/secret manual.

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

### 4. Mark the original message seen

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

### 5. Reply on Telegram

```powershell
$reply = Invoke-RestMethod -Method Post `
  -Uri ($base + '/sendMessage') `
  -ContentType 'application/json' `
  -Body (@{ chat_id = '<CHAT_ID>'; text = '<REPLY_TEXT>' } | ConvertTo-Json -Compress)
```

Return only safe evidence:

```powershell
[pscustomobject]@{
  reaction_ok = $reaction.ok
  reply_ok = $reply.ok
  reply_message_id = $reply.result.message_id
} | ConvertTo-Json -Compress
```

### 6. Clear only after successful handling

After both reaction and reply succeed, call:

```text
notification(action='dismiss_channel',
             input={'channel': 'mcp.telegram', 'force': null,
                    'reason': 'continue: reacted and replied; message_id=<new id>'},
             reasoning='clear the handled Telegram notification')
```

If dismissal is guarded or fails, do not force it merely to make the queue look clean. Preserve the notification and report the exact error.

### 7. Report evidence

Report these facts to the coordinating agent:

- original message id
- reaction success
- new reply message id
- notification dismissal result
- live model/state when recovery verification is part of the task
- confirmation that no credential, credential-bearing URI, project code, or unapproved config was printed/changed

## Failure branches

- **No `shell` capability:** ask the config owner to repair the canonical capability surface; do not guess an MCP registration.
- **No secret file / missing field:** report the missing local secret path. Do not ask the human to paste a credential into chat.
- **401/unauthorized:** treat the stored credential as invalid or revoked; request secure rotation.
- **Reaction fails but send succeeds:** report partial completion; do not claim full handling.
- **Human pasted credential:** acknowledge the message with the existing bot if possible, warn the human to revoke/regenerate, leave configuration untouched, and keep the task pending until secure local injection is confirmed.