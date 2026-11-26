#!/bin/bash
#description=Nightly: pull ghcr.io/catduckgnaf/inferzero:latest (built from the latest official upstream release), recreate the inferzero container from its Unraid template, health-check it, and roll back if it fails or is much slower.
#arrayStarted=true
#
# Unraid User Script. Installed at /boot/config/plugins/user.scripts/scripts/Inferzero-Auto-Update/script.
# Source: catduckgnaf/catduck-unraid-templates docker/inferzero/unraid-auto-update.sh.
#
# Safe to rerun. Never touches models or the expert cache. A release that fails the check is
# remembered by image ID and skipped until a newer image is published.

set -u
NAME=inferzero
IMAGE=ghcr.io/catduckgnaf/inferzero
PORT=8095
STATE=/mnt/user/appdata/inferzero-auto-update
HIST=$STATE/history.csv
BAD=$STATE/bad-images
NOTIFY=/usr/local/emhttp/webGui/scripts/notify
REBUILD=/usr/local/emhttp/plugins/dynamix.docker.manager/scripts/rebuild_container
BUSY_WAIT_MIN=30        # wait this long for an in-flight request to finish
START_WAIT_MIN=15       # model load and expert cache fill
SLOWER_LIMIT_PCT=60     # roll back below this share of the last good tokens/s

mkdir -p "$STATE"; touch "$BAD"
[ -f "$HIST" ] || echo "date,result,release,image,tok_s" > "$HIST"
log() { echo "$(date '+%F %T') $*"; }
note() { "$NOTIFY" -e "Inferzero auto-update" -s "$1" -d "$2" -i "$3" >/dev/null 2>&1 || true; }
release_of() { docker run --rm --entrypoint /bin/sh "$1" -c 'head -n1 /opt/inferzero/bin/PREBUILT.txt' 2>/dev/null | awk '{print $2}' | cut -d- -f1; }
props() { curl -s -m 10 "http://127.0.0.1:$PORT/props"; }

docker inspect "$NAME" >/dev/null 2>&1 || { log "no $NAME container; nothing to do"; exit 0; }
repo=$(docker inspect "$NAME" --format '{{.Config.Image}}')
case "$repo" in
  "$IMAGE:latest"|"$IMAGE") ;;
  *) log "$NAME runs $repo, not $IMAGE:latest (pinned on purpose?); skipping"; exit 0 ;;
esac

old_id=$(docker inspect "$NAME" --format '{{.Image}}')
docker pull -q "$IMAGE:latest" >/dev/null || { log "pull failed"; note "Pull failed" "docker pull $IMAGE:latest failed" warning; exit 1; }
new_id=$(docker image inspect "$IMAGE:latest" --format '{{.Id}}')
old_rel=$(release_of "$old_id"); new_rel=$(release_of "$new_id")

if [ "$new_id" = "$old_id" ]; then log "up to date ($old_rel)"; exit 0; fi
if grep -qx "$new_id" "$BAD"; then
  log "$new_rel ($new_id) failed before; keeping $old_rel"
  docker tag "$old_id" "$IMAGE:latest"   # keep the local latest on the running image
  exit 0
fi

# Do not cut off a request in flight.
for _ in $(seq 1 "$BUSY_WAIT_MIN"); do
  props | grep -q '"busy":true' || break
  log "busy; waiting"; sleep 60
done
if props | grep -q '"busy":true'; then
  log "still busy after $BUSY_WAIT_MIN min; trying tomorrow"
  docker tag "$old_id" "$IMAGE:latest"
  exit 0
fi

last_good=$(awk -F, '$2=="updated" || $2=="baseline" {v=$5} END {print v}' "$HIST")
docker tag "$old_id" "$IMAGE:rollback"
log "updating $old_rel -> $new_rel"
"$REBUILD" "$NAME" >/dev/null 2>&1

check() {
  for _ in $(seq 1 $((START_WAIT_MIN * 6))); do
    curl -s -m 5 "http://127.0.0.1:$PORT/health" | grep -q '"ok"' && break
    sleep 10
  done
  curl -s -m 5 "http://127.0.0.1:$PORT/health" | grep -q '"ok"' || { echo "no health after $START_WAIT_MIN min"; return 1; }
  model=$(curl -s -m 10 "http://127.0.0.1:$PORT/v1/models" | sed -n 's/.*"model":"\([^"]*\)".*/\1/p' | head -n1)
  # The first request after a start warms kernels and caches; time the second one.
  for _ in 1 2; do
    out=$(curl -s -m 300 "http://127.0.0.1:$PORT/v1/chat/completions" -H 'Content-Type: application/json' \
      -d "{\"model\":\"$model\",\"messages\":[{\"role\":\"user\",\"content\":\"Explain how PCIe lanes are allocated in a dual socket server, in detail.\"}],\"max_tokens\":200,\"temperature\":0,\"stream\":false}")
  done
  tok_s=$(echo "$out" | sed -n 's/.*"predicted_per_second":\([0-9.]*\).*/\1/p' | head -n1)
  [ -n "$tok_s" ] || { echo "test completion failed: $(echo "$out" | head -c 200)"; return 1; }
  echo "$tok_s"
}

if res=$(check); then
  tok_s=$res
  if [ -n "$last_good" ] && awk -v n="$tok_s" -v o="$last_good" -v p="$SLOWER_LIMIT_PCT" 'BEGIN {exit !(n < o * p / 100)}'; then
    reason="generation $tok_s tok/s against $last_good before"
  else
    echo "$(date '+%F %T'),updated,$new_rel,$new_id,$tok_s" >> "$HIST"
    log "updated to $new_rel, $tok_s tok/s"
    note "Updated to $new_rel" "inferzero $old_rel -> $new_rel, test generation $tok_s tok/s" normal
    exit 0
  fi
else
  reason=$res
fi

# Roll back to the image that was running.
log "check failed ($reason); rolling back to $old_rel"
docker logs "$NAME" > "$STATE/failed-$new_rel.log" 2>&1 || true
echo "$new_id" >> "$BAD"
docker tag "$IMAGE:rollback" "$IMAGE:latest"
"$REBUILD" "$NAME" >/dev/null 2>&1
echo "$(date '+%F %T'),rolled_back,$new_rel,$new_id,${tok_s:-}" >> "$HIST"
if back=$(check); then
  note "Rolled back $new_rel" "$new_rel failed the check ($reason). Back on $old_rel ($back tok/s). $new_rel is skipped until a newer image." warning
else
  note "Rollback FAILED" "$new_rel failed ($reason) and $old_rel did not come back: $back. Check the inferzero container." alert
  exit 1
fi
