#!/usr/bin/env bash
set -euo pipefail

URL="${FUPA_URL_M2:-https://www.fupa.net/league/landesliga_nord/standing}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_FILE="$ROOT_DIR/src/data/standings-m2.json"

mkdir -p "$(dirname "$OUT_FILE")"

echo "[fetch-standings-m2] Fetching standings from $URL..."

python3 - "$URL" "$OUT_FILE" <<'PY'
import json
import re
import sys
import urllib.request

url, out_file = sys.argv[1], sys.argv[2]

req = urllib.request.Request(
    url,
    headers={
        "User-Agent": (
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
            "AppleWebKit/537.36 (KHTML, like Gecko) "
            "Chrome/124.0.0.0 Safari/537.36"
        ),
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
        "Accept-Language": "de-DE,de;q=0.9,en;q=0.8",
    },
)

with urllib.request.urlopen(req, timeout=20) as resp:
    html = resp.read().decode("utf-8", errors="ignore")

m = re.search(r"window\.REDUX_DATA\s*=\s*(\{.*?\});?\s*</script>", html, re.S)
if not m:
    print("[fetch-standings-m2] Error: Could not find window.REDUX_DATA in page.", file=sys.stderr)
    sys.exit(1)

redux_data = json.loads(m.group(1))
raw_standings = (
    redux_data.get("dataHistory", [{}])[0]
    .get("LeagueStandingPage", {})
    .get("total", {})
    .get("data", {})
    .get("standings", [])
)

if not raw_standings:
    print("[fetch-standings-m2] Error: Standings list is empty.", file=sys.stderr)
    sys.exit(1)

roman = {2: " II", 3: " III", 4: " IV"}
rows = []

for entry in raw_standings:
    team_obj = entry.get("team", {})
    base_name = (team_obj.get("name") or {}).get("full") or ""
    level = team_obj.get("level", 1)
    suffix = roman.get(level, "")
    team_name = f"{base_name}{suffix}" if suffix and not base_name.endswith(suffix) else base_name

    wins = int(entry.get("wins", 0))
    draws = int(entry.get("draws", 0))
    defeats = int(entry.get("defeats", 0))
    goal_diff = int(entry.get("goalDifference", 0))

    rows.append(
        {
            "rank": int(entry.get("rank", 0)),
            "team": team_name,
            "matches": int(entry.get("matches", 0)),
            "wins": wins,
            "draws": draws,
            "defeats": defeats,
            "sun": f"{wins}-{draws}-{defeats}",
            "goalDifference": goal_diff,
            "points": int(entry.get("points", 0)),
        }
    )

with open(out_file, "w", encoding="utf-8") as f:
    json.dump(rows, f, ensure_ascii=False, indent=2)
    f.write("\n")

print(f"[fetch-standings-m2] Wrote {len(rows)} rows to {out_file}")
PY
