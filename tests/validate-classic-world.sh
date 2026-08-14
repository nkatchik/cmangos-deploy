#!/usr/bin/env bash

set -euo pipefail

compose_file=${COMPOSE_FILE:-compose-classic.yaml}
database_service=${DATABASE_SERVICE:-database}
root_password=${MARIADB_ROOT_PASSWORD:-password}

query_scalar() {
  docker compose -f "$compose_file" exec -T "$database_service" \
    mariadb -N -s -u root -p"$root_password" mangos -e "$1"
}

expect_equal() {
  local description=$1
  local expected=$2
  local query=$3
  local actual
  actual=$(query_scalar "$query")
  if [[ "$actual" != "$expected" ]]; then
    echo "$description: expected $expected, got $actual" >&2
    exit 1
  fi
  echo "ok - $description"
}

expect_equal \
  "all four retained raids exist with a five-character cap" \
  4 \
  "SELECT COUNT(*) FROM instance_template WHERE map IN (249,309,409,469) AND maxPlayers=5;"

expect_equal \
  "all four retained raids still have an entrance" \
  4 \
  "SELECT COUNT(DISTINCT target_map) FROM areatrigger_teleport WHERE target_map IN (249,309,409,469);"

expect_equal \
  "AQ20, AQ40, and Naxxramas instance templates are absent" \
  0 \
  "SELECT COUNT(*) FROM instance_template WHERE map IN (509,531,533);"

expect_equal \
  "no area trigger reaches a disabled raid" \
  0 \
  "SELECT COUNT(*) FROM areatrigger_teleport WHERE target_map IN (509,531,533);"

expect_equal \
  "disabled raid creature and gameobject spawns are absent" \
  0 \
  "SELECT (SELECT COUNT(*) FROM creature WHERE map IN (509,531,533)) + (SELECT COUNT(*) FROM gameobject WHERE map IN (509,531,533));"

expect_equal \
  "AQ war effort and Scourge Invasion events are absent" \
  0 \
  "SELECT COUNT(*) FROM game_event WHERE entry IN (17,22,89,90,91,92,93,94,95,96,97,98,99,120,121,122,123,124,125,126,127,128,129,130,131,132,133,134,135);"

expect_equal \
  "retained raid map defaults are configured for scaling" \
  4 \
  "SELECT COUNT(*) FROM custom_raid_scaling WHERE map_id IN (249,309,409,469) AND creature_id=0 AND calibration_players=5;"

expect_equal \
  "pre-cutoff world bosses are configured for scaling" \
  10 \
  "SELECT COUNT(*) FROM custom_raid_scaling WHERE (map_id=0 AND creature_id=12397) OR (map_id=1 AND creature_id=6109) OR (map_id IN (0,1) AND creature_id IN (14887,14888,14889,14890));"

expect_equal \
  "representative post-cutoff raid quests have no quest givers" \
  0 \
  "SELECT (SELECT COUNT(*) FROM creature_questrelation WHERE quest IN (8286,8743,9121,9250)) + (SELECT COUNT(*) FROM gameobject_questrelation WHERE quest IN (8286,8743,9121,9250));"

echo "Classic 1.8.4 cutoff and five-character raid policy validated."
