---
name: agent-memory-molt-policy
description: |
  Cross-model policy for deciding when LingTai agents should update or compact Pad/LingTai, summarize and rebuild conversation context, and perform a molt. Use when setting agent memory budgets, interpreting context pressure, or standardizing behavior across models; it does not replace context-manual's mandatory pre-molt store and session-journal procedure.
version: 1.2.0
last_changed_at: "2026-08-04T23:45:00+08:00"
tags: [workflow, reference]
---

# Agent Memory and Molt Policy

## 1. Measure the real window

Let `W` be the Agent's actual current context window from
`_meta.agent_meta.agent_state.token_usage.session.context_window` or the resolved
manifest. Do not infer `W` from a model nickname. Let `C` be current context
tokens, `P` the estimated Pad tokens, and `L` the estimated LingTai tokens.

Use percentages of `W` as the primary policy. Absolute token examples are only
examples and must scale when `W` changes.

## 2. Separate accuracy updates from length compaction

### Pad accuracy

Update Pad whenever its living index meaningfully changes: active task, plan,
owner, blocker, next action, important path, or handoff. Move completed narrative
and durable facts to knowledge instead of leaving them in Pad.

This accuracy update is not a request to rewrite or compress the whole file.

### LingTai identity

At a task end, update LingTai only if the experience genuinely changed enduring
operating style, responsibility, relationship, taste, safety posture, or trust
model. If identity did not change, do not edit LingTai. Do not mechanically
rewrite it at every task boundary or molt.

### Length guardrails

Treat these as deliberately loose emergency ceilings, not target sizes:

| Store | Warning | Mandatory compaction |
|---|---:|---:|
| Pad | `P >= 0.10 * W` | `P >= 0.15 * W` |
| LingTai | `L >= 0.15 * W` | `L >= 0.20 * W` |
| Pad + LingTai | — | `P + L >= 0.25 * W` |

Compact earlier at any size when the store is dominated by duplicate rules,
expired tasks, conflicting instructions, or completed narrative.

At a molt boundary, verify Pad and LingTai. If Pad is accurate, LingTai has no
identity change, and no size/semantic guardrail is crossed, carry them forward
unchanged. Do not perform ritual rewrites.

## 3. Context-pressure ladder

| Context usage `C / W` | Action |
|---|---|
| `< 0.60` | Work normally. Prefer a-priori summary for predictable bulk and daemons for noisy work. |
| `>= 0.60` | Inspect large consumed tool results; batch summarize obsolete raw output. |
| `>= 0.75` | Ensure Pad is accurate; prepare one end-of-task LingTai/knowledge/skill pass; avoid unnecessary raw bulk. |
| Sustained `>= 0.85` | Make one batched summarize pass and one context rebuild. If still above 85%, or recovery is insufficient and the current task no longer needs carried context, tend stores and molt. |
| `>= 1.00` | Emergency boundary. The runtime may force one rebuild; if recovery remains above target, molt immediately. |

Do not loop summarize/rebuild. Task completion alone is not an automatic molt.
Use a natural task boundary to molt only when context pressure, explicit human
request, conversation confusion, or another trigger below makes the reset worth
its cost.

## 4. Independent molt triggers

Molt regardless of context percentage when any of these applies:

1. `_meta.agent_meta.agent_state.context.molt` reports the since-last-molt
   cache-miss budget reached. Default budget: 1,000,000 uncached-input tokens;
   it survives refresh/restart.
2. The human explicitly requests a molt/reset.
3. The conversation has become internally confused enough that a successor
   briefing is safer than continuing.
4. A summarize/rebuild attempt cannot restore context below the operational
   recovery target.

## 5. Absolute examples

For `W = 500,000`:

- Start context cleanup around 300,000.
- Prepare stores around 375,000.
- Sustained 425,000 is the 85% molt boundary.
- Pad warning / mandatory: 50,000 / 75,000.
- LingTai warning / mandatory: 75,000 / 100,000.
- Pad + LingTai combined mandatory ceiling: 125,000.

For `W = 300,000`:

- Start context cleanup around 180,000.
- Prepare stores around 225,000.
- Sustained 255,000 is the 85% molt boundary.
- Pad warning / mandatory: 30,000 / 45,000.
- LingTai warning / mandatory: 45,000 / 60,000.
- Pad + LingTai combined mandatory ceiling: 75,000.

Therefore fixed suggestions such as “DeepSeek Flash at 500k, every other model at
300k” are not safe molt points unless those numbers have first been translated
into fractions of the actual window. Reaching 100% is an accident line, not a
normal molt target.

## 6. Mandatory pre-molt handoff

Before calling `context(action="molt")`:

1. Tend Pad, LingTai, knowledge, and skills only where needed.
2. Write the validated session-journal child under
   `knowledge/session-journal/<date>-molt-<count>-<slug>/KNOWLEDGE.md`.
3. Update the session-journal parent index.
4. Write a successor briefing with state, accomplishments, remaining work,
   collaborators, paths, risks, and first next action.
5. Pass the child path as `session_journal_path` to the molt call.

Read `context-manual` for the exact validated procedure and templates.

## 7. Telegram lifecycle handoff

When the Agent has a verified Eon Telegram outbound route, add this mandatory boundary immediately before an Agent-initiated molt:

1. Finish the durable handoff far enough that `context(action="molt")` is the next lifecycle step.
2. Send an “entering molt now” Telegram notice from the Agent's own window with the reason, honest recovery ETA in minutes, current task state, and first post-recovery action.
3. Persist the successful account/chat/message ID, timestamp, ETA, and requested base `👌` recovery reaction in the session-journal child or Pad.
4. After recovery, use the recovered Agent's own tool action to react to that exact notice directly with base `👌`, report actual recovery time, and resume the task/cadence. Do not attempt `👌🏿` first or substitute another emoji; if base `👌` fails, preserve the typed failure receipt and report the lifecycle acknowledgement as blocked.

Read `telegram-molt-lifecycle` for the full templates, evidence contract, send-failure branch, and no-credential rule.

A system-forced molt can begin without a live Agent turn, so Agent policy alone cannot guarantee the pre-notice; that needs a runtime pre-molt hook. After such a forced molt, never fabricate a notice or reaction. Immediately send a truthful recovery report with the actual interruption and route the missing hook as an operational gap.

## 8. Evaluate after real use

At a meaningful review point, compare before/after:

- context usage at task boundaries;
- since-last-molt cache-miss tokens and cache rate;
- Pad/LingTai size and duplication;
- time needed for a post-molt Agent to resume work;
- missed commitments, contradictory rules, or degraded task quality;
- human feedback on continuity and responsiveness.

Adjust percentages only from observed outcomes. Do not lower thresholds merely
because a task ended, and do not raise them so far that durable memory permanently
consumes a large share of every context window.
