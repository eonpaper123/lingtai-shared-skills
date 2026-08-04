---
name: telegram-progress-cadence
description: >
  Rawle's standing Telegram responsiveness procedure: ingress first delivers, the runtime applies 👀
  when the Agent opens the message in its current turn, and long tasks use task-scoped cadence plus
  a chained delayed self-email checkpoint.
version: 1.4.0
last_changed_at: "2026-08-04T23:25:00+08:00"
tags: [telegram, progress, responsiveness, long-running, workflow]
---

# Telegram progress cadence

## Standing contract

For every task from Rawle on Telegram:

1. Authorized LingTai ingress must first receive and successfully deliver Rawle's message; raw polling, receipt, or queueing must not place 👀.
2. When the delivered message enters the Agent's current turn and is opened, the runtime immediately places 👀 on the original message, before deeper interpretation or execution. That 👀 means exactly “The Agent opened this successfully delivered message.” If the open-time hook fails, repairing it must be the Agent's first action and the fallback must be reported.
3. At the same safe Agent/tool boundary, read the ordered producer window and send a short acknowledgement in the same bot/chat.
4. If the task is expected or observed to exceed five minutes, report every five minutes from receipt until final delivery, unless Rawle explicitly sets another interval for that current task.
5. When a long task starts, schedule one delayed self-email for the next due checkpoint. After each progress message, consume/dismiss the delivered reminder and schedule exactly one next checkpoint. At terminal delivery, stop chaining and clean any later-arriving stale reminder without creating another.
6. Send a complete final result; progress messages do not replace delivery.

The Agent-open 👀 does not claim completed interpretation, execution, or completion. It must not appear before Agent visibility or be delayed until analysis ends. Project-specific work must be performed and reported by the owning project total unless Rawle explicitly assigns another executor. The controller routes, monitors, and verifies.

## Fast acknowledgement

Prefer `gpt-5.6-luna` for the quick acknowledgement/initial plan **when that route is already available and authorized**. Do not refresh/restart or stay silent merely to reach Luna. If Luna is unavailable in the current live route, use the fastest currently available model and say so explicitly.

Template:

```text
已收到：<任务>
准备先用 <模型> 做 <plan/first check>，再用 <模型/工具> 执行 <main work>。
首个可验证结果预计：<time>。
若超过 5 分钟，我会按当前任务的有效间隔汇报进度。
```

Do not place a decorative 👀 in the acknowledgement text as a substitute for the reaction on the original message. Retain the source message ID, Agent-open reaction receipt, and acknowledgement reply ID when evidence matters. The acknowledgement must be short. Do not front-load the whole analysis.

## Task-scoped clock

Anchor `T0` at message receipt, not when implementation starts. The default interval is five minutes. A newer explicit interval from Rawle for the current task (for example, 30 minutes) replaces the default only for that task. Material completion, failure, deployment, blocker, or risk changes are still reported immediately. When that task ends, the next task returns to the five-minute default unless Rawle sets another interval.

Send at `T0 + interval`, `+2 × interval`, and so on until one of these terminal events:

- final result sent;
- Rawle cancels or supersedes the task;
- task is explicitly handed to another bot and that bot has acknowledged ownership in its own Telegram window.

A blocked task is still active. Report the blocker and what would unblock it at the current interval; do not disappear.

## Chained delayed self-email

Use LingTai delayed self-email as the durable one-shot clock. A promise kept only in model context is not a timer.

At task start:

```text
email(action='send',
      input={'address': '<self>', 'subject': 'TELEGRAM CHECKPOINT — <task>',
             'message': '<task/chat anchor, effective interval, what to inspect>',
             'delay': <interval seconds>, 'cc': null, 'bcc': null,
             'attachments': null, 'mode': 'peer', 'type': 'normal'},
      reasoning='arm the next Telegram progress checkpoint')
```

Rules:

- Keep exactly one current checkpoint per active task. Do not schedule a whole series in advance.
- After the reminder arrives, re-read the latest producer steering before acting. If the task is still active, send the due progress update, dismiss the consumed self-email, and schedule exactly one next checkpoint.
- If a progress update is sent early for a material change, the already-scheduled reminder cannot be cancelled through the email tool. Mark it superseded; when it arrives, dismiss it as stale and do not open a duplicate cadence branch. Schedule one newly anchored checkpoint only when needed.
- At terminal delivery, do not schedule another checkpoint. Any already-scheduled time capsule may still arrive because delayed email has no cancellation verb; dismiss it as terminal/stale and do not chain it.
- Record safe evidence: `status=sent`, requested delay/target time, and later the delivered self-email ID plus its producer-specific `dismiss`/`read` handling. Do not expose private mailbox IDs to Rawle or peers.

## Progress template

```text
【<任务> · <HH:MM> 进度】
已完成：<verified work>
正在做：<current step>
下一步：<next step>
阻塞/风险：<none or exact blocker>
ETA：<time/range + assumption>
```

Use evidence, not vague activity language. Say “tests not run” or “awaiting credential file” instead of implying success.

## Keep work observable

Do not start an opaque operation expected to block the agent loop for more than five minutes.

- Use async shell/daemon/first-class backend for long processes and return to the agent loop.
- Split audits and implementations into milestones that finish within roughly 3–4 minutes.
- Before each potentially long step, send the due progress update first.
- Check the clock after every tool result and before starting the next branch.
- Maintain a truthful Task Card for substantial work, but still send Telegram updates; a Task Card is not a substitute for channel communication.
- If a provider call unexpectedly exceeds the effective interval, send the overdue update immediately when control returns and shorten the next step.

## Delegated work

The delegating controller must tell the project total:

- Rawle's exact task and latest correction;
- the required Telegram bot/channel for replies;
- the effective cadence and current `T0`;
- the delayed self-email chaining/terminal-cleanup requirement;
- whether Luna is available or the fallback must be disclosed;
- the evidence and final deliverable expected.

The controller must not send substitute progress as though it came from the project total. It may tell Rawle that routing succeeded or report a delivery failure.

## Molt during an active task

A molt does not silently cancel the visibility contract. Immediately before an Agent-initiated molt, follow `telegram-molt-lifecycle`: send the pre-molt notice with reason/ETA/current state, persist its message ID, and after recovery react to that exact notice with Rawle's requested recovery reaction before resuming progress. Chain the next checkpoint from the recovery status message while the task remains active.

If a system-forced molt occurred before the Agent had a live turn to send the notice, report that boundary truthfully on recovery and resume cadence immediately. Do not fabricate a pre-notice, and do not use a later reaction as retroactive proof.

## Final message

The final Telegram delivery should state:

- conclusion/result;
- key evidence or artifact path;
- validation performed and anything unverified;
- remaining risk or next action;
- completion status (`completed`, `blocked`, `cancelled`, or `partial`).

After final delivery, stop the self-email chain, consume any later stale reminder without chaining, and retire the Task Card so stale progress does not continue.
