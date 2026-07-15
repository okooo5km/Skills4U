---
name: orchard
description: "Use the local Orchard CLI to interact with macOS Apple apps and services from Codex: Calendar, Reminders, Clock, Mail, Contacts, Notes, Music, Weather, Messages, Location/Maps, and Apple Shortcuts. Resolves either a globally installed `orchard` command or the bundled `Orchard.app/Contents/MacOS/orchard-cli`. Use when a task asks to read or manage local calendar events, reminders, Apple Mail, contacts, notes, iMessage/SMS, Apple Music playback/library, weather, current time/timezones, geocoding, routes, current location, or local Shortcuts."
metadata:
  version: "0.6.0"
  updated: "2026-07-15"
  tested_with:
    orchard_app: "0.6.0 (15)"
    orchard_cli: "0.6.0"
---

# Orchard

## Quick Start

Use Orchard's native CLI for local Apple-app automation on macOS. Resolve the CLI path first, then call that path for every command.

Run the bundled resolver first. If your current working directory is not this skill directory, use the absolute path to `scripts/resolve-orchard.sh`.

```bash
ORCHARD_BIN="$(./scripts/resolve-orchard.sh --bin)"
ORCHARD_ROUTE="$(./scripts/resolve-orchard.sh --route)"
ORCHARD_APP_PATH="$(./scripts/resolve-orchard.sh --app)"
"$ORCHARD_BIN" --version
```

Route rules:

- `global_cli`: use the globally installed `orchard` command. Do not reject it because it points at a Debug app; development machines often do that.
- `bundle_cli`: use the bundled `orchard-cli` inside `Orchard.app`. Continue the task. Optionally tell the user they can install the CLI tool from Orchard later for shell-wide `orchard` access.
- `missing_app`: stop and tell the user to install `Orchard.app`; there is no CLI to call.

Prefer `--json` for machine-readable output. Orchard 0.6.0 returns an outer JSON envelope:

```json
{"output":"...string, object, or array...","success":true}
```

The `output` value may already be a JSON object/array, plain text, JSON text, or prose followed by JSON such as `Found 2 events:\n{...}`. If `output` is a string that contains JSON, strip text before the first JSON object/array and parse the nested payload before reasoning over records.

For the full command matrix, read `references/commands.md`.

## Known Pitfalls

- Use `"$ORCHARD_BIN" <domain> <command> ...`, not a hard-coded `orchard`, unless `command -v orchard` was the selected route.
- Check leaf-command help with `"$ORCHARD_BIN" <domain> <command> --help` or `"$ORCHARD_BIN" help <domain> <command>`; both print the same output.
- In zsh loops, never pass a multi-word command through a scalar like `"$ORCHARD_BIN" $cmd`; zsh keeps it as one argument. Use an array, or `eval` only for trusted static command strings.
- Negative numeric values must use the equals form: `--lng1=-122.4194`, `--lon=-117.1201`. With a space (`--lng1 -122.4194`) the parser reads the value as a new flag and fails with a usage error; shell quoting does not help because quotes never reach argv.
- `orchard mail read` supports `--date-from`/`--date-to` (ISO 8601) and `--offset` for time windows and pagination. If the installed CLI rejects these flags (older builds), fall back to `--limit` plus local `date_sent` filtering and state possible truncation when results hit the limit.
- Treat help output and the installed CLI as source of truth. If this skill and CLI disagree, run `"$ORCHARD_BIN" <domain> <command> --help` and adapt.

## Core Rules

- Use ISO 8601 timestamps for all date ranges. Include timezone offsets when the user means local time, e.g. `2026-06-03T08:00:00+08:00`.
- Convert relative dates before calling Orchard. "Yesterday 08:00" must become a concrete timestamp.
- Before creating calendar events or reminders, list calendars/lists and choose the right writable target. Do not dump everything into a default list/calendar unless the user explicitly asks.
- Before update/delete/mark/cancel operations, read the target and capture its ID.
- Treat destructive operations as real local mutations. For deletes, bulk updates, sending mail/messages, and scheduled sends, confirm intent unless the user explicitly requested the action.
- Before running an Apple Shortcut, list or open the matching shortcut first. Use `shortcuts run` only with `--confirm` and `--reason`, and confirm with the user unless they explicitly requested that exact run.
- Never print huge email bodies or private data unnecessarily. Fetch summaries first, then read full content only for messages that matter.

## Common Workflows

### Daily Context

```bash
"$ORCHARD_BIN" clock time --timezone Asia/Shanghai --json
"$ORCHARD_BIN" weather get --location Jinan --granularity daily --start-date YYYY-MM-DD --end-date YYYY-MM-DD --json
"$ORCHARD_BIN" calendar info --type events --from YYYY-MM-DDT00:00:00+08:00 --to YYYY-MM-DDT00:00:00+08:00 --json
"$ORCHARD_BIN" reminder info --type reminders --status incomplete --json
```

When summarizing reminders, filter stale/completed/noisy records yourself if Orchard returns more than requested.

### Mail Triage

```bash
"$ORCHARD_BIN" mail refresh --json
"$ORCHARD_BIN" mail read --type list --limit 100 --json
"$ORCHARD_BIN" mail read --type list --date-from 2026-07-01T00:00:00+08:00 --date-to 2026-07-15T00:00:00+08:00 --limit 100 --json
"$ORCHARD_BIN" mail read --type content --message-id MESSAGE_ID --json
```

Mail listing supports `--limit`, `--mailbox`, `--account`, `--offset` for pagination, and `--date-from`/`--date-to` (ISO 8601) for time windows. If the result count equals the limit, page with `--offset` or say the scan may be truncated instead of pretending coverage is complete. On older builds that reject the date/offset flags, fall back to `--limit` plus local `date_sent` filtering.

Only fetch full email bodies for likely important mail: accounts, billing, support, customer, legal, platform review, security, collaboration, or anything the user asked to inspect.

### Calendar And Reminder Writes

```bash
"$ORCHARD_BIN" calendar info --type calendars --json
"$ORCHARD_BIN" calendar create --title "Call" --start 2026-06-03T15:00:00+08:00 --end 2026-06-03T15:30:00+08:00 --calendar-id CALENDAR_ID --alarms 15 --json

"$ORCHARD_BIN" reminder info --type lists --json
"$ORCHARD_BIN" reminder create --title "Follow up" --list-id LIST_ID --due-date 2026-06-03T18:00:00+08:00 --priority 5 --json
```

Use `priority 0-9`; higher numbers are more important in Orchard output. Mark complete with:

```bash
"$ORCHARD_BIN" reminder update --reminder-id REMINDER_ID --completed true --json
```

### Notes And Contacts

Search before creating duplicates:

```bash
"$ORCHARD_BIN" contacts search --query "Alice" --limit 10 --json
"$ORCHARD_BIN" notes search --query "project name" --limit 20 --json
```

Notes content is HTML for create/update. If the user gives Markdown, convert it to simple HTML first.

### Messages

```bash
"$ORCHARD_BIN" messages read --type chats --query "search term" --limit 20 --json
"$ORCHARD_BIN" messages read --type messages --chat "+15551234567" --limit 50 --json
"$ORCHARD_BIN" messages send --to "+15551234567" --text "Text here" --service iMessage --json
```

Confirm before sending unless the user directly instructs sending exact text.

### Shortcuts

```bash
"$ORCHARD_BIN" shortcuts list --summary --json
"$ORCHARD_BIN" shortcuts open --name "Shortcut name" --json
"$ORCHARD_BIN" shortcuts run --name "Shortcut name" --input "Text" --confirm --reason "User requested this exact shortcut run" --json
```

Prefer `shortcuts list --summary` before running. Use `--input-path` and `--output-path` for file handoff.

## Troubleshooting

- If a command asks for macOS privacy permissions, tell the user which app/service needs permission and retry after permission is granted.
- If a command returns `Orchard.app is not running`, start `"$ORCHARD_APP_PATH"` when it is non-empty; otherwise run `open -a Orchard`. Wait a few seconds, then retry once with the same `ORCHARD_BIN`.
- If a command returns `Invalid response from Orchard.app`, treat it as an Orchard.app bridge/permission/runtime issue, not necessarily a CLI syntax issue. Retry once, then ask the user to check that Orchard.app is running and has the relevant macOS privacy permissions.
- If Apple Mail, Calendar, or Reminders data looks stale, run the relevant refresh/list command again and state the timestamp of the scan.
- If `--json` output contains a long HTML email body, summarize only the relevant parts; do not paste the entire body.
- If a flag is not accepted, trust `"$ORCHARD_BIN" <domain> <command> --help` for the installed version and adapt.
