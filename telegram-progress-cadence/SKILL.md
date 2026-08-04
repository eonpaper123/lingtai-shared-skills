---
name: telegram-progress-cadence
description: >
  Rawle's standing Telegram responsiveness procedure for long tasks: react with 👀 immediately,
  send a fast acknowledgement and model/plan note (prefer gpt-5.6-luna when already available),
  then report every five minutes until final delivery. Use for any Rawle task expected or observed
  to exceed five minutes, including delegated project work and blocked waits.
version: 1.0.0
last_changed_at: "2026-08-04T16:58:00+08:00"
tags: [telegram, progress, responsiveness, long-running, workflow]
---

# Telegram progress cadence

## Standing contract

For every task from Rawle on Telegram:

1. React 👀 on the original message as soon as it is seen.
2. Send a short acknowledgement immediately in the same bot/chat.
3. If the task is expected or observed to exceed five minutes, send a progress update every five minutes from receipt until final delivery.
4. Send a complete final result; progress messages do not replace delivery.

Project-specific work must be performed and reported by the owning project total unless Rawle explicitly assigns another executor. The controller routes, monitors, and verifies.

## Fast acknowledgement

Prefer `gpt-5.6-luna` for the quick acknowledgement/initial plan **when that route is already available and authorized**. Do not refresh/restart or stay silent merely to reach Luna. If Luna is unavailable, use the fastest currently available model and say so explicitly.

Template:

```text
👀 已收到：<任务>
准备先用 <模型> 做 <plan/first check>，再用 <模型/工具> 执行 <main work>。
首个可验证结果预计：<time>。
若超过 5 分钟，我会每 5 分钟汇报进度。
```

The acknowledgement must be short. Do not front-load the whole analysis.

## Five-minute clock

Anchor `T0` at message receipt, not when implementation starts. Send at `T0 + 5m`, `+10m`, and so on until one of these terminal events:

- final result sent;
- Rawle cancels or supersedes the task;
- task is explicitly handed to another bot and that bot has acknowledged ownership in its own Telegram window.

A blocked task is still active. Report the blocker and what would unblock it every five minutes; do not disappear.

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
- If a provider call unexpectedly exceeds five minutes, send the overdue update immediately when control returns and shorten the next step.

## Delegated work

The delegating controller must tell the project total:

- Rawle's exact task and latest correction;
- the required Telegram bot/channel for replies;
- the five-minute cadence and current `T0`;
- whether Luna is available or the fallback must be disclosed;
- the evidence and final deliverable expected.

The controller must not send substitute progress as though it came from the project total. It may tell Rawle that routing succeeded or report a delivery failure.

## Final message

The final Telegram delivery should state:

- conclusion/result;
- key evidence or artifact path;
- validation performed and anything unverified;
- remaining risk or next action;
- completion status (`completed`, `blocked`, `cancelled`, or `partial`).

After final delivery, cancel any reminder/scheduler state and retire the Task Card so stale progress does not continue.