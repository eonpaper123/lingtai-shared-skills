---
name: telegram-steering-stream
description: >
  Rawle's standing rule that every Telegram message is timely steering, not an isolated FIFO job.
  Read when Telegram messages arrive during active work, when Rawle sends several short fragments,
  before deciding whether to merge scope or delegate a subtask, or when a station bridge queues input
  behind a long Agent turn. Preserves source ordering, latest-scope/authorization checks, actual-read
  receipts, safe tool boundaries, and the separate runtime injection gap.
version: 1.0.0
last_changed_at: "2026-08-04T22:44:00+08:00"
tags: [telegram, workflow, communication, routing]
---

# Telegram steering stream

## Core contract

Treat every Telegram message from Rawle as a steering input that must be considered promptly with the Agent's current work. Do not model the conversation as unrelated FIFO jobs that can wait until a long outer turn finishes.

Rawle often sends one sentence at a time and may complete or revise an instruction across several messages. The operative contract is therefore the ordered, current producer conversation—not whichever single message first started the task.

This does not make every new sentence an unquestionable command. Apply evidence, context, authorization, safety, and critical judgment; surface real conflicts respectfully.

## Live-turn procedure

### 1. Read the producer source at the next safe boundary

When an `mcp.telegram` event appears, inspect the producer-owned current message and any adjacent unhandled messages in the same conversation. Notification summaries are not enough when text is truncated, ambiguous, media-bearing, or missing ordering anchors.

React 👀 to each Rawle message only after this Agent actually reads it in the live turn. A bridge/listener/webhook reaction is never an Agent receipt.

If a deterministic tool call is already running, do not corrupt or kill it merely to simulate immediacy. Incorporate new steering at the first safe Agent/tool boundary. Before any externally consequential side effect, re-check the latest producer messages even if an earlier plan was already approved.

### 2. Build one ordered steering window

For the same Telegram conversation, consider together:

- the current message and immediately preceding unhandled fragments;
- the active task, plan, owners, blockers and promised cadence;
- later corrections, cancellations, scope reductions or authorization changes;
- the exact message/time ordering and which items this Agent has actually acknowledged.

Do not wait for Rawle to package a multi-sentence paragraph. Do not assume a fragment is the final word when another message is already present.

### 3. Decide: merge, revise, split or stop

**Merge** when the new steering is compatible with the current objective and ownership. Update the active plan and Task Card rather than inventing a duplicate task.

**Revise or stop** when the new message changes scope, priority, cadence, authorization or the desired output. A newer specific instruction overrides an older default for that task; preserve unrelated standing rules.

**Split** when work is genuinely independent, mutually blocking, noisy, or needs separate expertise:

- use a daemon for disposable, context-isolated analysis/execution where the parent needs only the conclusion;
- use an avatar/persistent project specialist only when durable ownership or an ongoing relationship is needed;
- keep the parent responsible for framing, authorization, review, synthesis, progress and Rawle-facing replies.

Do not delegate merely to avoid understanding Rawle's combined intent. Before a review/delegation, re-read the latest Telegram producer window and pass the resulting contract—including what is out of scope and which side effects remain unauthorized—to the child/reviewer.

### 4. Reply and keep cadence

Acknowledge promptly in the same Telegram window, state how the new steering changes or joins the plan, and name the model/body route. For an active long task, a material steering reply counts as an immediate update but does not permit future silence; continue the task-specific cadence Rawle currently set.

When steering changes a tracked plan, update the Task Card promptly and follow `task-card-chinese`: all human-facing headings and prose must be Chinese, with English retained only for necessary technical proper nouns, commands, paths, model/API/protocol names, hashes and exact identifiers.

If several fragments can be answered coherently together, one anchored response may synthesize them, but the Agent must still have actually read each message and must not let an earlier fragment disappear.

## Runtime/bridge acceptance boundary

Agent procedure alone cannot deliver a Telegram update into an already-running outer host turn. A bridge that only logs `accepted/queued` and waits for the turn to end does not satisfy Rawle's steering-stream requirement.

A conforming runtime should, at minimum:

1. preserve per-conversation update order and event/update IDs;
2. de-duplicate delivery without dropping later fragments;
3. make new steering visible to the running Agent at the next safe tool/LLM boundary, not only after the outer task completes;
4. allow the Agent to revise/cancel not-yet-executed work before external side effects;
5. keep reaction/reply actions Agent-originated and once-only;
6. avoid killing a currently executing non-idempotent tool call solely to inject text;
7. retain an explicit queued/deferred state when no safe boundary exists, with observable latency and recovery evidence.

Until the runtime path is verified, label this as a delivery gap. Do not claim that installing this skill makes queued bridges real-time.

## Evidence checklist

For policy acceptance, record:

- producer account/conversation and ordered message/event/update IDs;
- arrival time, first Agent-visible safe boundary and actual-read time;
- Agent-originated 👀 receipts and same-channel reply IDs;
- whether steering merged, revised, stopped or split the active work, with the reason;
- daemon/avatar handoff contract when delegated;
- latest-instruction recheck before external side effects/review;
- bridge/runtime delivery latency and whether input entered the running turn or waited for a new outer turn;
- confirmation that no duplicate listener, `getUpdates`, unsafe interrupt, credential exposure, restart, refresh, push or publish was used merely to fake immediacy.
