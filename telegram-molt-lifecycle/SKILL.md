---
name: telegram-molt-lifecycle
description: >
  Rawle's Telegram lifecycle contract for LingTai molt. Before an Agent-initiated molt, announce
  reason, ETA and resumable state and persist the message receipt; after recovery, react to that
  notice with 👌🏿 and report actual time. Read before any Agent-initiated context molt or after a
  system-forced molt with no pre-notice. It exposes the forced-molt runtime-hook boundary and never
  authorizes credential provisioning.
version: 1.0.0
last_changed_at: "2026-08-04T22:33:00+08:00"
tags: [telegram, workflow, lifecycle, context]
---

# Telegram molt lifecycle

## Standing contract

For every Agent that has a verified Rawle Telegram outbound route:

1. Immediately before the Agent calls `context(action="molt")`, send a Telegram notice from that Agent's own bot/window.
2. State the molt reason, honest ETA in minutes, current task state, and the first post-recovery action.
3. Persist the successful outbound receipt so the successor can locate the exact notice message.
4. After recovery, make the first lifecycle acknowledgement an Agent-initiated reaction on that same notice: Rawle requested `👌🏿`.
5. Report actual recovery time and resume or re-route the interrupted task.

This complements `context-manual`; it does not replace the mandatory four-store, session-journal, and successor-briefing procedure.

## Agent-initiated molt procedure

### 1. Prepare the resumable state

Follow `context-manual` first: tend only the durable stores that need changes, write the validated session-journal child, update the parent index, and prepare the successor briefing. Do not send the Telegram notice while substantial pre-molt work remains; “entering molt now” must mean the molt call is the next lifecycle step.

Choose an honest ETA. It is an estimate for molt/reconstruction and first recovery handling, not a promise that external providers cannot delay. If uncertain, give a bounded range and name the assumption.

### 2. Send the pre-molt notice

Use only the Agent's already-verified Telegram producer or the reviewed `telegram-station-outbound` fallback. Do not create, request, print, or copy credentials.

Template:

```text
【凝蜕通知】
状态：我现在进入凝蜕。
原因：<context pressure / cache-miss budget / explicit reset / confusion>
预计恢复：<N 分钟或 N–M 分钟；assumption>
当前任务：<verified state>
恢复后第一步：<exact next action>
```

Verify the transport receipt. Save at least:

```yaml
molt_notice:
  platform: telegram
  account: <station account>
  chat_id: <non-secret chat id>
  message_id: <outbound notice message id>
  sent_at: <ISO 8601>
  eta_minutes: <number or range>
  requested_recovery_reaction: "👌🏿"
  status: pending_recovery
```

Put this small block in the session-journal child or Pad so it survives the molt. Never store the bot token or a credential-bearing URI.

If the send fails, diagnose once and use an already-authorized same-channel fallback if one exists. Do not delay an emergency hard-boundary molt indefinitely. Record the failed attempt and exact blocker in the session journal; after recovery, report that the pre-notice failed instead of pretending it was sent.

### 3. Molt

Call `context(action="molt")` only after the notice receipt and its durable locator are recorded, except for the explicit emergency failure branch above.

## Recovery procedure

1. Reconstruct from Pad, the molt summary, session journal, and current producer messages.
2. Locate the exact pre-molt Telegram message from the durable `molt_notice` block. Do not search by vague text when a message ID exists.
3. From the recovered Agent's own tool action, attempt to add Rawle's requested `👌🏿` reaction to that message.
4. If Telegram explicitly rejects that exact reaction as unsupported, preserve the one failure receipt, retry once with base `👌`, and reply in the same thread that the platform rejected the skin-tone variant. Do not loop and do not claim `👌🏿` succeeded when it did not.
5. Send a short recovery status with actual elapsed time, current task state, and the first resumed action. Resume the ordinary five-minute cadence if a long task is still active.
6. Mark the durable lifecycle block `complete` with reaction/reply receipts, or archive it in the session journal; do not leave a stale pending marker.

A transport success proves the API accepted the action. It does not prove Rawle visually saw it; keep transport and visual claims separate.

## System-forced molt boundary

A system-forced molt can begin before the Agent receives another live turn. In that case an Agent behavior rule cannot guarantee a pre-notice; only a runtime pre-molt hook can do so.

After waking from a forced molt with no stored notice receipt:

1. Do not fabricate or backdate a pre-molt message.
2. Immediately tell Rawle in the Agent's own Telegram window that a system-forced molt occurred, why the pre-notice could not be sent, the actual interruption duration if known, and the resumed task state.
3. Record and route the missing runtime hook as an operational gap to control/project ownership.
4. Continue the task and five-minute cadence.

A later message or reaction is recovery evidence only; it cannot retroactively prove a pre-notice existed.

## Agents without a verified Telegram route

Do not guess an MCP registration, reuse another bot's credential, or ask Rawle to paste a token. Before an Agent-initiated molt, notify the project total through the existing internal channel and request that the total use its verified Rawle Telegram route to relay the notice. Mark direct compliance blocked by routing until an authorized owner provisions and verifies the canonical route.

## Evidence checklist

Keep these non-secret facts for acceptance:

- Agent-initiated or system-forced classification;
- pre-notice outbound message ID and timestamp, or explicit reason it was impossible/failed;
- announced ETA and actual recovery duration;
- session-journal/Pad locator carrying the receipt;
- post-recovery reaction tool/API receipt and exact emoji accepted;
- fallback explanation if `👌🏿` was rejected and base `👌` was used;
- recovery reply message ID;
- confirmation that no credential, unapproved configuration, project code, restart, refresh, push, or publish side effect occurred merely to satisfy the notification.
