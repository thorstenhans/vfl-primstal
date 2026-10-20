#!/usr/bin/env bash
set -euo pipefail

PROFILE="${IG_PROFILE:-vflprimstal}"
COUNT="${IG_COUNT:-9}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMG_DIR="$ROOT_DIR/src/images/instagram"
DATA_FILE="$ROOT_DIR/src/data/instagram.json"

mkdir -p "$IMG_DIR" "$(dirname "$DATA_FILE")"

echo "[fetch-instagram] Fetching latest $COUNT posts for @$PROFILE..."

python3 - "$PROFILE" "$COUNT" "$IMG_DIR" "$DATA_FILE" <<'PY'
import datetime
import html as htmllib
import json
import os
import re
import sys
import urllib.request

profile = sys.argv[1]
count = int(sys.argv[2])
img_dir = sys.argv[3]
data_file = sys.argv[4]

ua = (
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
    "AppleWebKit/537.36 (KHTML, like Gecko) "
    "Chrome/124.0.0.0 Safari/537.36"
)


def fetch_text(url: str, dest: str = "document", site: str = "none") -> str:
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
    with urllib.request.urlopen(req, timeout=25) as resp:
        return resp.read().decode("utf-8", errors="ignore")


def download_image(url: str, dest_path: str) -> None:
    req = urllib.request.Request(
        url,
        headers={
            "User-Agent": ua,
            "Accept": "image/avif,image/webp,image/apng,image/*,*/*;q=0.8",
            "Referer": "https://www.instagram.com/",
        },
    )
    with urllib.request.urlopen(req, timeout=30) as resp, open(dest_path, "wb") as f:
        f.write(resp.read())


def pk_to_unix_ts(pk: int) -> int:
    # Instagram 64-bit Snowflake ID epoch: 1314220021721 ms
    if pk > 10**14:
        return int(((pk >> 23) + 1314220021721) // 1000)
    return pk


# Step 1: Fetch public profile embed page (contains top 6 posts in 1080p + timestamps)
embed_html = fetch_text(f"https://www.instagram.com/{profile}/embed/", dest="iframe", site="cross-site")
posts_by_code = {}

m = re.search(r'"contextJSON":"((?:\\.|[^"\\])*)"', embed_html)
if m:
    ctx_str = json.loads('"' + m.group(1) + '"')
    ctx = json.loads(ctx_str).get("context", {})
    for item in ctx.get("graphql_media", []):
        sm = item.get("shortcode_media", {})
        code = sm.get("shortcode")
        if not code:
            continue
        pk = int(sm.get("id") or 0)
        ts = int(sm.get("taken_at_timestamp") or pk_to_unix_ts(pk))
        edges = (sm.get("edge_media_to_caption") or {}).get("edges") or []
        caption = ""
        if edges and isinstance(edges[0].get("node"), dict):
            caption = edges[0]["node"].get("text") or ""
        posts_by_code[code] = {
            "code": code,
            "pk": pk,
            "timestamp_unix": ts,
            "caption": caption,
            "image_url": sm.get("display_url") or "",
        }

# Step 2: Fetch the newest post page to obtain the full recent timeline grid (12+ posts)
if posts_by_code:
    newest_code = max(posts_by_code.values(), key=lambda p: p["pk"])["code"]
    post_html = fetch_text(f"https://www.instagram.com/p/{newest_code}/", dest="document", site="none")
    for m_item in re.finditer(
        r'"pk":"([0-9]+)","__isXIGPolarisMedia":"[^"]+","accessibility_caption":(?:"(?:\\.|[^"\\])*"|null),"caption":(\{"text":"(?:\\.|[^"\\])*"\}|null),"code":"([A-Za-z0-9_-]+)","seo_canonical_url":[^,]+,"display_uri":"((?:\\.|[^"\\])*)"',
        post_html,
    ):
        pk = int(m_item.group(1))
        cap_raw = m_item.group(2)
        code = m_item.group(3)
        display_uri = json.loads('"' + m_item.group(4) + '"')

        caption = ""
        if cap_raw != "null":
            try:
                caption = json.loads(cap_raw).get("text") or ""
            except Exception:
                pass

        existing = posts_by_code.get(code, {})
        posts_by_code[code] = {
            "code": code,
            "pk": max(existing.get("pk", 0), pk),
            "timestamp_unix": existing.get("timestamp_unix") or pk_to_unix_ts(pk),
            "caption": existing.get("caption") or caption,
            # Prefer 1080p display_url from embed if available, otherwise display_uri
            "image_url": existing.get("image_url") or display_uri,
            "needs_full_res": not bool(existing.get("image_url")),
        }

if not posts_by_code:
    print(f"[fetch-instagram] Error: Could not discover any posts for @{profile}.", file=sys.stderr)
    sys.exit(1)

# Sort strictly descending by Instagram Snowflake PK (newest chronological post first)
sorted_posts = sorted(posts_by_code.values(), key=lambda p: p["pk"], reverse=True)[:count]

# Clean old images
for fname in os.listdir(img_dir):
    if re.match(r"^ig_\d+\.jpg$", fname):
        os.remove(os.path.join(img_dir, fname))

metadata_out = []

for idx, post in enumerate(sorted_posts, start=1):
    code = post["code"]
    img_url = post["image_url"]

    # Upgrade to full 1080p image via single-post embed page if not already from profile embed
    if post.get("needs_full_res"):
        try:
            p_embed = fetch_text(f"https://www.instagram.com/p/{code}/embed/", dest="iframe", site="cross-site")
            m_img = re.search(r'<img class="EmbeddedMediaImage"[^>]+src="([^"]+)"', p_embed)
            if m_img:
                img_url = htmllib.unescape(m_img.group(1))
        except Exception:
            pass

    filename = f"ig_{idx}.jpg"
    dest_path = os.path.join(img_dir, filename)
    download_image(img_url, dest_path)

    iso_ts = datetime.datetime.fromtimestamp(
        int(post["timestamp_unix"]), tz=datetime.timezone.utc
    ).strftime("%Y-%m-%dT%H:%M:%SZ")

    metadata_out.append(
        {
            "index": idx,
            "filename": filename,
            "caption": post["caption"],
            "timestamp": iso_ts,
        }
    )
    print(f"  [{idx}/{len(sorted_posts)}] Saved {filename} (code: {code}, timestamp: {iso_ts})")

with open(data_file, "w", encoding="utf-8") as f:
    json.dump(metadata_out, f, ensure_ascii=False, indent=2)
    f.write("\n")

print(f"[fetch-instagram] Successfully saved {len(metadata_out)} images and wrote {data_file}")
PY
