#!/usr/bin/env bash
set -euo pipefail

PROFILE="${IG_PROFILE:-vflprimstal}"
COUNT="${IG_COUNT:-9}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMG_DIR="$ROOT_DIR/src/images/instagram"
DATA_FILE="$ROOT_DIR/src/data/instagram.json"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

# Ensure instaloader is available (use global binary or cached temporary venv)
if command -v instaloader >/dev/null 2>&1; then
  INSTALOADER_BIN="instaloader"
  PYTHON_BIN="python3"
else
  VENV_DIR="${TMPDIR:-/tmp}/instaloader-venv"
  if [[ ! -x "$VENV_DIR/bin/instaloader" ]]; then
    echo "[fetch-instagram] Installing instaloader into $VENV_DIR..."
    python3 -m venv "$VENV_DIR"
    "$VENV_DIR/bin/pip" install --quiet --upgrade pip instaloader
  fi
  INSTALOADER_BIN="$VENV_DIR/bin/instaloader"
  PYTHON_BIN="$VENV_DIR/bin/python3"
fi

echo "[fetch-instagram] Discovering latest $COUNT posts for @$PROFILE..."

DISCOVERED_JSON="$TMP_DIR/discovered.json"

"$PYTHON_BIN" - "$PROFILE" "$COUNT" "$DISCOVERED_JSON" <<'PY'
import json
import re
import sys
import urllib.request

profile = sys.argv[1]
count = int(sys.argv[2])
out_path = sys.argv[3]

ua = (
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
    "AppleWebKit/537.36 (KHTML, like Gecko) "
    "Chrome/124.0.0.0 Safari/537.36"
)

def fetch_html(url: str, dest: str = "document", site: str = "none") -> str:
    req = urllib.request.Request(
        url,
        headers={
            "User-Agent": ua,
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8",
            "Accept-Language": "de-DE,de;q=0.9,en-US;q=0.8,en;q=0.7",
            "Sec-Fetch-Dest": dest,
            "Sec-Fetch-Mode": "navigate",
            "Sec-Fetch-Site": site,
        },
    )
    with urllib.request.urlopen(req, timeout=20) as resp:
        return resp.read().decode("utf-8", errors="ignore")

# Step 1: Fetch public profile embed page to obtain initial recent shortcodes
embed_html = fetch_html(f"https://www.instagram.com/{profile}/embed/", dest="iframe", site="cross-site")
posts_by_code = {}
captions_by_code = {}

m = re.search(r'"contextJSON":"((?:\\.|[^"\\])*)"', embed_html)
if m:
    ctx_str = json.loads('"' + m.group(1) + '"')
    ctx = json.loads(ctx_str).get("context", {})
    for item in ctx.get("graphql_media", []):
        sm = item.get("shortcode_media", {})
        code = sm.get("shortcode")
        pk = sm.get("id") or sm.get("taken_at_timestamp") or 0
        if code:
            posts_by_code[code] = int(pk)
            edges = (sm.get("edge_media_to_caption") or {}).get("edges") or []
            if edges and isinstance(edges[0].get("node"), dict):
                captions_by_code[code] = edges[0]["node"].get("text") or ""

if not posts_by_code:
    for m_sc in re.finditer(r'"shortcode":"([A-Za-z0-9_-]+)"', embed_html):
        code = m_sc.group(1)
        posts_by_code.setdefault(code, 0)

# Step 2: Fetch the newest post page to obtain the full recent timeline grid (12+ posts)
if posts_by_code:
    newest_code = max(posts_by_code.items(), key=lambda kv: kv[1])[0]
    post_html = fetch_html(f"https://www.instagram.com/p/{newest_code}/", dest="document", site="none")
    for m_item in re.finditer(
        r'"pk":"([0-9]+)","__isXIGPolarisMedia":"[^"]+","accessibility_caption":(?:"(?:\\.|[^"\\])*"|null),"caption":(\{"text":"(?:\\.|[^"\\])*"\}|null),"code":"([A-Za-z0-9_-]+)"',
        post_html,
    ):
        pk_str, cap_raw, code = m_item.group(1), m_item.group(2), m_item.group(3)
        posts_by_code[code] = max(posts_by_code.get(code, 0), int(pk_str))
        if cap_raw != "null":
            try:
                captions_by_code[code] = json.loads(cap_raw).get("text") or ""
            except Exception:
                pass

# Sort strictly descending by Instagram Snowflake PK (newest chronological post first)
sorted_codes = [
    code for code, _ in sorted(posts_by_code.items(), key=lambda kv: kv[1], reverse=True)
][:count]

with open(out_path, "w", encoding="utf-8") as f:
    json.dump({"shortcodes": sorted_codes, "captions": captions_by_code}, f)
PY

SHORTCODES=()
while IFS= read -r line; do
  [[ -n "$line" ]] && SHORTCODES+=("$line")
done < <("$PYTHON_BIN" -c 'import json, sys; [print(c) for c in json.load(open(sys.argv[1]))["shortcodes"]]' "$DISCOVERED_JSON")

if [[ "${#SHORTCODES[@]}" -eq 0 ]]; then
  echo "[fetch-instagram] Error: Could not discover any shortcodes for @$PROFILE." >&2
  exit 1
fi

echo "[fetch-instagram] Found ${#SHORTCODES[@]} shortcodes: ${SHORTCODES[*]}"

INSTALOADER_ARGS=(
  "--no-videos"
  "--no-profile-pic"
  "--no-captions"
  "--no-compress-json"
  "--dirname-pattern=$TMP_DIR"
  "--filename-pattern={date_utc}_UTC"
)

if [[ -n "${IG_SESSIONFILE:-}" ]]; then
  INSTALOADER_ARGS+=("--sessionfile=$IG_SESSIONFILE")
fi

TARGETS=()
for sc in "${SHORTCODES[@]}"; do
  TARGETS+=("-$sc")
done

echo "[fetch-instagram] Downloading posts via instaloader..."
"$INSTALOADER_BIN" "${INSTALOADER_ARGS[@]}" -- "${TARGETS[@]}"

mkdir -p "$IMG_DIR" "$(dirname "$DATA_FILE")"
rm -f "$IMG_DIR"/ig_*.jpg

echo "[fetch-instagram] Renaming images to ig_1.jpg .. ig_${COUNT}.jpg and writing metadata..."
"$PYTHON_BIN" - "$TMP_DIR" "$IMG_DIR" "$DATA_FILE" "$COUNT" "$DISCOVERED_JSON" <<'PY'
import datetime
import glob
import json
import os
import shutil
import sys

tmp_dir, img_dir, data_file, count, disc_file = (
    sys.argv[1],
    sys.argv[2],
    sys.argv[3],
    int(sys.argv[4]),
    sys.argv[5],
)

with open(disc_file, "r", encoding="utf-8") as f:
    discovered_captions = json.load(f).get("captions", {})

json_files = sorted(glob.glob(os.path.join(tmp_dir, "*_UTC.json")), reverse=True)[:count]
posts = []

for idx, jf in enumerate(json_files, start=1):
    stem = jf[:-5]  # strip .json
    # Single image post is <stem>.jpg; carousel post has <stem>_1.jpg as first slide
    candidates = [f"{stem}.jpg", f"{stem}_1.jpg"] + sorted(glob.glob(f"{stem}_*.jpg"))
    img_src = next((c for c in candidates if os.path.isfile(c)), None)
    if not img_src:
        continue

    filename = f"ig_{idx}.jpg"
    dest_path = os.path.join(img_dir, filename)
    shutil.copy2(img_src, dest_path)

    with open(jf, "r", encoding="utf-8") as f:
        meta = json.load(f).get("node", {})

    code = meta.get("shortcode") or meta.get("code") or ""

    # Extract caption (from instaloader JSON or discovered post metadata)
    caption = ""
    if isinstance(meta.get("caption"), dict):
        caption = meta["caption"].get("text") or ""
    elif isinstance(meta.get("caption"), str):
        caption = meta["caption"]
    else:
        edges = (meta.get("edge_media_to_caption") or {}).get("edges") or []
        if edges and isinstance(edges[0].get("node"), dict):
            caption = edges[0]["node"].get("text") or ""
    if not caption and code in discovered_captions:
        caption = discovered_captions[code]

    # Extract timestamp
    ts_unix = meta.get("taken_at_timestamp") or meta.get("taken_at") or meta.get("date")
    if ts_unix:
        timestamp = datetime.datetime.fromtimestamp(
            int(ts_unix), tz=datetime.timezone.utc
        ).strftime("%Y-%m-%dT%H:%M:%SZ")
    else:
        timestamp = ""

    posts.append(
        {
            "index": idx,
            "filename": filename,
            "caption": caption,
            "timestamp": timestamp,
        }
    )
    print(f"  [{idx}/{len(json_files)}] Saved {filename} (timestamp: {timestamp})")

with open(data_file, "w", encoding="utf-8") as f:
    json.dump(posts, f, ensure_ascii=False, indent=2)
    f.write("\n")

print(f"[fetch-instagram] Wrote {len(posts)} entries to {data_file}")
PY
