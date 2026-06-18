# Orchard Command Reference

Orchard version inspected: `0.6.0`.

All domains support `--help`. Most leaf commands support `--json`. Examples below use `orchard` as shorthand; when `SKILL.md` has resolved `ORCHARD_BIN`, call `"$ORCHARD_BIN"` instead.

## Contents

- Help And Shell Pitfalls
- Top Level
- Calendar
- Reminders
- Clock
- Mail
- Contacts
- Notes
- Music
- Weather
- Messages
- Location
- Shortcuts
- Parsing Pattern

## Help And Shell Pitfalls

- Use `orchard <domain> <command> --help` for leaf commands, e.g. `orchard calendar info --help`.
- Do not use `orchard help <domain> <command>` for leaf commands in 0.6.0; it falls back to top-level help.
- In zsh, a scalar containing spaces is not split into multiple argv items. This is wrong:

```bash
cmd="calendar info"
orchard $cmd --help
```

Use an array, or `eval` only when the command string is trusted and static:

```bash
cmd=(calendar info)
orchard "${cmd[@]}" --help

eval "orchard calendar info --help"
```

## Top Level

```bash
orchard --version
orchard --help
orchard help calendar
orchard help reminder
orchard help clock
orchard help mail
orchard help contacts
orchard help notes
orchard help music
orchard help weather
orchard help messages
orchard help location
orchard help shortcuts
```

Subcommands:

- `calendar`: Calendar events management
- `reminder`: Reminders management
- `clock`: Time and timezone utilities
- `mail`: Apple Mail management
- `contacts`: Apple Contacts management
- `notes`: Apple Notes management
- `music`: Apple Music control and management
- `weather`: Weather information
- `messages`: Apple Messages management
- `location`: Location and maps services
- `shortcuts`: Apple Shortcuts discovery and execution

## Calendar

```bash
orchard calendar info --type calendars --json
orchard calendar info --type events --from 2026-06-03T00:00:00+08:00 --to 2026-06-04T00:00:00+08:00 --json

orchard calendar create \
  --title "Event title" \
  --start 2026-06-03T15:00:00+08:00 \
  --end 2026-06-03T16:00:00+08:00 \
  --calendar-id CALENDAR_ID \
  --location "Office" \
  --notes "Agenda" \
  --alarms 15,60 \
  --json

orchard calendar create --title "All-day" --start 2026-06-03T00:00:00+08:00 --end 2026-06-03T23:59:59+08:00 --all-day --json
orchard calendar update --event-id EVENT_ID --title "New title" --start 2026-06-03T16:00:00+08:00 --end 2026-06-03T17:00:00+08:00 --json
orchard calendar delete --event-id EVENT_ID --json
orchard calendar convert --date 2026-06-03T00:00:00+08:00 --calendar chinese --json
```

Calendar convert targets: `gregorian`, `buddhist`, `chinese`, `hebrew`, `islamic`, `islamicCivil`, `indian`, `japanese`, `persian`, `coptic`, `ethiopicAmeteMihret`, `ethiopicAmeteAlem`, `iso8601`.

## Reminders

```bash
orchard reminder info --type lists --json
orchard reminder info --type reminders --status incomplete --json
orchard reminder info --type reminders --list-id LIST_ID --status all --json

orchard reminder create --title "Task" --list-id LIST_ID --due-date 2026-06-03T18:00:00+08:00 --priority 5 --notes "Context" --json
orchard reminder update --reminder-id REMINDER_ID --completed true --json
orchard reminder update --reminder-id REMINDER_ID --title "New task" --due-date 2026-06-04T09:00:00+08:00 --priority 1 --notes "New notes" --json
orchard reminder delete --reminder-id REMINDER_ID --json

orchard reminder list-create --name "Project" --color "#3B82F6" --json
orchard reminder list-update --list-id LIST_ID --name "New name" --color "#22C55E" --json
orchard reminder list-delete --list-id LIST_ID --json
```

Status values: `all`, `incomplete`, `completed`.

## Clock

```bash
orchard clock time --json
orchard clock time --timezone Asia/Shanghai --json
orchard clock time --timezone America/Los_Angeles --to-timezone Asia/Shanghai --time 2026-06-03T09:00:00-07:00 --json

orchard clock util --action list_timezones --region Asia --json
orchard clock util --action difference --time1 2026-06-03T09:00:00+08:00 --time2 2026-06-03T18:00:00+08:00 --json
```

Utility actions: `list_timezones`, `difference`.

## Mail

```bash
orchard mail accounts --json
orchard mail refresh --json
orchard mail refresh --account "Account name" --json

orchard mail read --type list --limit 100 --json
orchard mail read --type unread --limit 50 --json
orchard mail read --type search --query "from:apple subject:receipt" --limit 20 --json
orchard mail read --type content --message-id MESSAGE_ID --json
orchard mail read --type thread --message-id MESSAGE_ID --json

orchard mail send --to "a@example.com,b@example.com" --cc "c@example.com" --from "me@example.com" --subject "Subject" --content "Body" --json
orchard mail send --to "a@example.com" --subject "Subject" --content "Body" --scheduled-time 2026-06-03T18:00:00+08:00 --json

orchard mail mark --message-ids "ID1,ID2" --status read --json
orchard mail mark --message-ids "ID1,ID2" --status unread --json

orchard mail scheduled list --json
orchard mail scheduled cancel --id SCHEDULED_EMAIL_ID --json
```

Read types: `search`, `content`, `unread`, `list`, `thread`.

Mail list records include fields such as `id`, `sender`, `sender_address`, `subject`, `date_sent`, `mailbox`, `is_read`, `is_flagged`, `has_attachments`, and often `summary`.

Important limitation in 0.6.0: `mail read` has no documented date range or offset flag. Filter returned `date_sent` locally and increase `--limit` when needed.

If returned messages equal the requested `--limit`, report that the time-window scan may be truncated. Do not claim complete coverage unless the fetched set extends older than the window start.

## Contacts

```bash
orchard contacts search --query "Alice" --limit 20 --json
orchard contacts details --contact-id CONTACT_ID --json

orchard contacts create --given-name "Alice" --family-name "Chen" --organization-name "Acme" --job-title "Founder" --phone "mobile:+15551234567" --email "work:alice@example.com" --note "Met at event" --json
orchard contacts update --contact-id CONTACT_ID --given-name "Alice" --phone "mobile:+15551234567" --email "work:alice@example.com" --json
orchard contacts delete --contact-id CONTACT_ID --json
```

Search before create to avoid duplicates.

## Notes

```bash
orchard notes search --query "keyword" --limit 20 --json
orchard notes create --title "Title" --folder "Folder name" --content "<h1>Title</h1><p>Body</p>" --json
orchard notes get --note-id NOTE_ID --format text --json
orchard notes get --note-id NOTE_ID --format html --json
orchard notes update --note-id NOTE_ID --content "<p>Updated HTML</p>" --json
orchard notes open --note-id NOTE_ID --json
```

Create/update content expects HTML.

## Music

```bash
orchard music control --action play --json
orchard music control --action pause --json
orchard music control --action next --json
orchard music control --action previous --json
orchard music control --action stop --json
orchard music control --action volume --value 50 --json
orchard music control --action shuffle --value true --json
orchard music control --action repeat --value one --json

orchard music info --type playback --json
orchard music info --type library --json
orchard music info --type albums --json
orchard music info --type playlists --json

orchard music search --query "artist or song" --type songs --limit 10 --json
orchard music play --type song --name "Song name" --json
orchard music play --type album --name "Album name" --json
orchard music play --type playlist --name "Playlist name" --json
orchard music play --type song --id SONG_ID --json

orchard music playlist create --name "Playlist" --description "Description" --json
orchard music playlist add --playlist-id PLAYLIST_ID --song-ids "SONG_ID1,SONG_ID2" --json
orchard music playlist remove --playlist-id PLAYLIST_ID --song-ids "SONG_ID1,SONG_ID2" --json
orchard music playlist delete --playlist-id PLAYLIST_ID --json
```

Control actions: `play`, `pause`, `next`, `previous`, `stop`, `volume`, `shuffle`, `repeat`.

Music info types: `playback`, `library`, `albums`, `playlists`.

Search types: `songs`, `albums`, `artists`.

## Weather

```bash
orchard weather get --location Jinan --granularity daily --start-date 2026-06-03 --end-date 2026-06-04 --json
orchard weather get --lat 36.6521 --lon 117.1201 --granularity hourly --start-date 2026-06-03T00:00:00+08:00 --end-date 2026-06-03T23:59:59+08:00 --json
```

Granularity values: `daily`, `hourly`. There is no `--days` flag in 0.6.0.

Weather records include condition, symbol, temperature high/low, precipitation chance/amount, UV index, wind, sun, moon phase, and location.

## Messages

```bash
orchard messages read --type chats --query "search term" --limit 20 --json
orchard messages read --type messages --chat "+15551234567" --limit 50 --json
orchard messages read --type messages --query "keyword" --limit 50 --json

orchard messages send --to "+15551234567" --text "Message" --service iMessage --json
orchard messages send --to "+15551234567" --text "Message" --service SMS --scheduled-time 2026-06-03T18:00:00+08:00 --json

orchard messages scheduled list --json
orchard messages scheduled cancel --id SCHEDULED_MESSAGE_ID --json
```

Read types: `chats`, `messages`.

In 0.6.0, `messages read --type chats` requires `--query` in practice even though help marks it optional.

Confirm before sending unless the user has provided exact text and requested send.

## Location

```bash
orchard location search --query "coffee near Jinan" --type search --json
orchard location search --query "coffee" --type nearby --lat 36.6521 --lon 117.1201 --json
orchard location search --query "Jinan" --type autocomplete --json

orchard location geocode --direction address_to_coords --address "Jinan, China" --json
orchard location geocode --direction coords_to_address --lat 36.6521 --lon 117.1201 --json

orchard location route --origin "Jinan Station" --destination "Jinan West Station" --transport transit --json
orchard location route --origin "36.6521,117.1201" --destination "36.668,116.997" --transport auto --json
orchard location current --json
```

Location search types: `search`, `nearby`, `autocomplete`.

Geocode directions: `address_to_coords`, `coords_to_address`.

Route transports: `auto`, `walk`, `transit`.

## Shortcuts

```bash
orchard shortcuts list --summary --json
orchard shortcuts list --folder-name "Folder" --query "invoice" --json
orchard shortcuts folders --json
orchard shortcuts open --name "Shortcut name" --json
orchard shortcuts open --id SHORTCUT_ID --json

orchard shortcuts run \
  --name "Shortcut name" \
  --input "Text input" \
  --output-path /tmp/shortcut-output.txt \
  --output-type public.plain-text \
  --execution-mode auto \
  --timeout-seconds 120 \
  --confirm \
  --reason "User requested this exact shortcut run" \
  --json
```

Run supports `--name` or `--id`; `--input` or `--input-path`; optional `--output-path`, `--output-type`, `--execution-mode`, and `--timeout-seconds`. `--confirm` and `--reason` are required by design.

## Parsing Pattern

Use this shape when a task needs robust shell-side parsing:

```bash
orchard calendar info --type events --from 2026-06-03T00:00:00+08:00 --to 2026-06-04T00:00:00+08:00 --json \
  | jq -r '.output' \
  | python3 -c 'import json,re,sys; s=sys.stdin.read(); m=re.search(r"([\\[{])", s); payload=s[m.start():] if m else s; print(json.dumps(json.loads(payload), ensure_ascii=False, indent=2))'
```

If `output` is already an object/array, use it directly. If `output` is plain text, summarize it directly. If it is JSON text prefixed by prose such as `Found 2 events:\n{...}`, strip everything before the first `{` or `[` before parsing.
