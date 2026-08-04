# Telegram delivery templates

Outcome-first, one language, 3–6 bullets. Escape every dynamic value per the
skill before filling a template; never put credentials, Bot API URIs, or tokens
in any field. Render the final string exactly once.

## Plain-text profile (default when rich output is unverified)

### Acknowledgement

```text
[Received] <short task name>

Working on it: <expected next evidence or ETA>.
```

### Progress (five-minute cadence for long tasks)

```text
[Progress] <short task name>

• Done: <one line>
• Next: <one line>
• ETA/risk: <one line>
```

### Final

```text
[Completed|Failed|Blocked] <short task name>

Result: <one-sentence outcome>
• Evidence: <artifact / commit / message id>
• Validation: <command/result> or "not run: reason"
• Risk / next step: <explicit status>
```

## HTML profile (only where parse_mode='HTML' is verified on this station)

Allowed tags: `<b>` title/status, `<i>` sparingly, `<code>` short identifiers,
`<pre>` short excerpt, `<a href="...">` reviewed public links. No tables, no
colours, no dynamic attributes, no inbound markup.

### Acknowledgement (HTML)

```html
<b>[Received] Short task name</b>

Working on it: <i>expected next evidence or ETA</i>.
```

### Progress (HTML)

```html
<b>[Progress] Short task name</b>

• Done: one line
• Next: one line
• ETA/risk: one line
```

### Final (HTML)

```html
<b>[Completed] Short task name</b>

Result: <code>one-sentence outcome</code>
• Evidence: <code>artifact / commit / message id</code>
• Validation: <code>command</code> — result, or "not run: reason"
• Risk / next step: explicit status
```

## Evidence checklist (record in the task/handoff, not in chat text)

- Transport: station/account, original message id, sent message id, selected
  profile, producer result.
- Visual: designated verifier + approved route, or "not yet confirmed".
- Gap: rich unavailable / document unsupported → state blocked/partial.
- Safety: no credential, Bot API URI, or token appears in message, artifact, or
  evidence.
