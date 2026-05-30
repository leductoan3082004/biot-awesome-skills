# INDEX.json + meta.json schema + jq recipes (context-save v4)

The routing fast-path. Restore reads `INDEX.json` (not 145 folders) to find a
topic; save patches one row. Per-topic detail lives in each folder's
`meta.json`.

## INDEX.json

Location: `~/.claude/projects/checkpoints/INDEX.json`

```json
{
  "schema": "context-save/v4",
  "topics": {
    "<topic-slug>": {
      "title": "human title",
      "summary": "<=200 chars, restore routes on this",
      "keywords": ["3-7", "routing", "tokens"],
      "folder": "<topic-slug>",
      "sessions": 7,
      "status": "in-progress",
      "last_updated": "2026-05-30T14:22Z",
      "branches": ["feat/x"],
      "related_topics": ["other-topic-slug"],
      "format": "eventlog"
    }
  }
}
```

- `folder` is relative to the checkpoint dir.
- `format`: `eventlog` (v4) or `legacy-v3` (until lazy-converted).
- `status`: `in-progress` | `resolved` | `abandoned`.

## meta.json (per topic folder)

Location: `~/.claude/projects/checkpoints/<topic-slug>/meta.json`

```json
{
  "schema": "context-save/v4",
  "topic": "<topic-slug>",
  "title": "human title",
  "summary": "<=200 chars",
  "keywords": ["..."],
  "sessions": 7,
  "status": "in-progress",
  "format": "eventlog",
  "created": "2026-05-20T...",
  "last_updated": "2026-05-30T14:22Z",
  "branches": ["feat/x"],
  "commits": ["a1b2c3d"],
  "related_topics": ["other-topic-slug"],
  "next_id": 14,
  "active_items": {
    "#12": "wire restore parallel agents",
    "#13": "needs user decision on cap size",
    "s3#2": "use append-only logs"
  }
}
```

- `next_id`: next free item id; bump after each assignment.
- `active_items`: id → one-line text for currently-OPEN progress items +
  ACTIVE decisions only. Bounded by active count, NOT history. Save reads this
  (not the logs) to reference/close prior ids; works even without restore-first.

## jq recipes

Assumes `CKPT=~/.claude/projects/checkpoints`, `INDEX=$CKPT/INDEX.json`.

Read one topic row:
```bash
jq --arg t "$SLUG" '.topics[$t]' "$INDEX"
```

List all topics (table-ish):
```bash
jq -r '.topics | to_entries[] | "\(.key)\t\(.value.sessions)\t\(.value.status)\t\(.value.summary)"' "$INDEX"
```

Upsert a topic row (write via tmp + mv for atomicity):
```bash
jq --arg t "$SLUG" --argjson row "$ROW_JSON" \
   '.topics[$t] = $row' "$INDEX" > "$INDEX.tmp" && mv "$INDEX.tmp" "$INDEX"
```

Detect stale rows (folder missing on disk):
```bash
jq -r '.topics | to_entries[] | .value.folder' "$INDEX" | while read -r f; do
  [ -d "$CKPT/$f" ] || echo "STALE: $f"
done
```

Read active_items + next_id from a topic's meta.json:
```bash
META="$CKPT/$SLUG/meta.json"
jq '{next_id, active_items}' "$META"
```

Update meta.json after a save (bump next_id, set active_items, bump sessions):
```bash
jq --argjson ni "$NEW_NEXT_ID" --argjson ai "$NEW_ACTIVE_ITEMS" \
   --arg lu "$NOW_ISO" \
   '.next_id=$ni | .active_items=$ai | .sessions+=1 | .last_updated=$lu' \
   "$META" > "$META.tmp" && mv "$META.tmp" "$META"
```

Bootstrap INDEX.json if missing:
```bash
[ -f "$INDEX" ] || echo '{"schema":"context-save/v4","topics":{}}' > "$INDEX"
```

## rebuild-index (self-heal)

When INDEX.json is missing/stale, scan folders ONCE and regenerate from each
`meta.json`:
```bash
echo '{"schema":"context-save/v4","topics":{}}' > "$INDEX.tmp"
for d in "$CKPT"/*/; do
  m="$d/meta.json"; [ -f "$m" ] || continue
  slug=$(basename "$d")
  row=$(jq '{title,summary,keywords,sessions,status,last_updated,branches,related_topics,format,folder:input_filename|split("/")[-2]}' "$m")
  jq --arg t "$slug" --argjson r "$row" '.topics[$t]=$r' "$INDEX.tmp" > "$INDEX.tmp2" && mv "$INDEX.tmp2" "$INDEX.tmp"
done
mv "$INDEX.tmp" "$INDEX"
```
(Legacy-v3 folders without meta.json are rebuilt from their `context.md`
frontmatter during lazy-convert; rebuild-index records them with
`format:"legacy-v3"` until then.)
