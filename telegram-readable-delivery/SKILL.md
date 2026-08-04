---
name: telegram-readable-delivery
description: >
  Capability-first decision tree for human-facing Telegram delivery: make readable
  message text the default, use lightweight emphasis on verified producers, and
  escalate to standalone HTML/chart/document artifacts only when they add value.
  Covers profile selection, escaping, outcome-first structure, transport evidence,
  and the structured-plain fallback; it provisions no credentials.
version: 1.1.0
last_changed_at: "2026-08-04T22:00:00+08:00"
tags: [telegram, rendering, workflow, escape]
---

# Telegram readable delivery

## When this applies

Any human-facing delivery to Telegram or another rich channel: acknowledgements,
progress, and final reports. Applies to the sending station only — another
station's capabilities are not evidence for this one. If the message is a
credential, a sensitive artifact, or for an unapproved recipient, stop: this
skill is not authorization to send it.

## Decision tree: pick the delivery path first

1. **Route first.** Prefer the station's active first-class Telegram producer.
   Use `reply` for an answer to a specific incoming message, `send` for a
   standalone message. If there is no first-class producer, use the station's
   approved fallback contract. It defaults to plain text; use an optional rich
   branch only after that fallback itself demonstrates `parse_mode` support and
   requires caller-owned escaping. Never emit raw markup expecting it to render.
2. **Probe the producer, not the network.** Read the active tool's schema/manual
   and confirm on the live tool surface: does it accept `parse_mode`? Which
   modes? Does it support `media.type='document'`? Recording that "another
   station supports HTML" is not capability.
3. **Choose the readable text baseline first**, using exactly one profile:
   - **Lightweight HTML text** — the default for non-trivial messages only when
     this producer has demonstrated `parse_mode='HTML'`. Use one short `<b>`
     outcome/title, selective bold labels, short paragraphs, bullets and
     punctuation. This is a normal Telegram text message, not a standalone HTML
     page or an HTML table.
   - **MarkdownV2 text** — only where the station has a tested escaper for every
     reserved character; never ad-hoc concatenation of dynamic text.
   - **Entity-formatted text** — only through a tested builder that computes
     Telegram-compatible offsets over the final Unicode text; never a hand-built
     plan combined with a parse-mode template.
   - **Structured plain text** — use when no rich profile is verified, parsing
     fails, the message is too small to benefit from markup, or reliability
     matters more than emphasis. Use visible headings, short paragraphs, compact
     bullets and punctuation; do not emit raw `**bold**`, fences, or pseudo-tables.
4. **Escalate to a rich artifact only when it adds value.** A standalone HTML
   report, chart/image, wide matrix, or document is not the default. Use a
   document only when the producer supports it, the approved non-secret artifact
   must stay intact, and inline text would be materially worse. Always accompany
   it with a short readable summary; never paste a local file path as delivery.
4. **Escape dynamic data for the chosen profile.** Every value not fixed in the
   template — user text, names, paths, errors, generated values — is data, not
   markup. The producer passes text and formatting through without an observed
   automatic escaping layer: the caller owns correctness.

## Controlled HTML subset (only when verified)

- Allowed: `<b>` for title/status, `<i>` sparingly, `<code>` for short
  identifiers, `<pre>` only for a short fixed-width excerpt, `<a href="...">`
  only for reviewed public links.
- Not allowed to rely on: colours, tables, dense tag hierarchy, dynamic
  attributes. Prefer no dynamic attributes at all.
- Inbound text must never supply tags, URLs, or entities.

## Dynamic-data escaping

For HTML text nodes escape in this exact order:

```
&  ->  &amp;
<  ->  &lt;
>  ->  &gt;
```

Escape `"` and `'` only if a value ever appears inside an attribute (prefer no
dynamic attributes). Use the deterministic helper:
`python scripts/escape_html.py < input.txt` (or pass text as arguments). It is
UTF-8 only, stdlib-only, and never touches the network.

For MarkdownV2, escape every reserved character outside documented special
contexts (`_ * [ ] ( ) ~ ` > # + - = | { } . ! \`). Do not use legacy
`Markdown` for new templates.

## Message shape and length

- Keep messages short and outcome-first: title/status line, one-sentence
  conclusion, then 3–6 evidence/validation/risk bullets, in one language.
- Acknowledge quickly; for tasks likely to exceed five minutes send a short
  evidence-based progress note at the five-minute cadence. Progress never
  replaces the final delivery.
- One Telegram message has a hard size limit; keep inline text small and attach
  bulky reports as documents where supported. Never front-load internal
  analysis, raw logs, or wide tables.

## Templates

Concise HTML and plain-text ack/progress/final templates live in
`assets/templates.md`. Render and escape the final string exactly once before
sending.

## Evidence: transport vs visual

- **Transport receipt:** station/account, original and sent message IDs, chosen
  profile, and the producer result. A successful API call proves transport only.
- **Visual confirmation:** a designated verifier confirms in an approved route
  that the rendered hierarchy is legible. Claim "rendered/rich" only after that
  confirmation; otherwise say "sent (transport verified), visual check
  pending".
- For a newly enabled renderer and every format-critical final delivery, retain
  both kinds of evidence.

## Failure and escalation branches

- **No verified rich profile / uncertain support:** send the clean plain-text
  profile; mark rich rendering unavailable/blocked for this station.
- **Parse error on send:** identify the single escaping/template defect, correct
  it, retry once, then downgrade to plain text. Do not blindly retry an
  ambiguous send; first determine whether the message already arrived.
- **Rate-limited / duplicate-blocked:** inspect the error metadata before
  retrying; do not double-send.
- **Format-critical final delivery without a capable producer on the originating
  channel:** escalate to that channel's config owner/project total. Do not answer
  through an unrelated channel; never silently claim HTML support, invent a
  producer registration, or change credentials/configuration.
- **Document requested but unsupported:** deliver plain text plus the artifact
  path/handoff, and state the gap as blocked/partial.

## Scripts and assets

- `scripts/escape_html.py` — deterministic UTF-8 escaper for Telegram HTML text
  nodes (not attributes), stdin or argv, no network.
- `assets/templates.md` — ack/progress/final templates in HTML and plain text,
  plus the evidence checklist.
