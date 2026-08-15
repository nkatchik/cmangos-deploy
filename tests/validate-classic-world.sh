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
  "all active dungeons and retained raids have a five-character cap" \
  0 \
  "SELECT COUNT(*) FROM instance_template WHERE maxPlayers > 0 AND maxPlayers <> 5;"

expect_equal \
  "Blackrock Spire is capped for one five-character group" \
  1 \
  "SELECT COUNT(*) FROM instance_template WHERE map=229 AND maxPlayers=5;"

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
  "retained raid trash uses isolated-elite calibration" \
  4 \
  "SELECT COUNT(*) FROM custom_raid_scaling WHERE creature_id=0 AND ((map_id IN (249,409,469) AND health_multiplier<=0.1201 AND damage_multiplier<=0.4001) OR (map_id=309 AND health_multiplier<=0.2201 AND damage_multiplier<=0.4501));"

expect_equal \
  "retained raid bosses keep extra health without higher per-hit damage" \
  4 \
  "SELECT COUNT(*) FROM custom_raid_scaling WHERE creature_id=0 AND boss_health_multiplier>health_multiplier AND ((map_id IN (249,409,469) AND ABS(damage_multiplier-0.40)<0.0001 AND ABS(boss_damage_multiplier-0.40)<0.0001) OR (map_id=309 AND ABS(damage_multiplier-0.45)<0.0001 AND ABS(boss_damage_multiplier-0.45)<0.0001));"

expect_equal \
  "retained raid encounter overrides use the safer damage ceiling" \
  0 \
  "SELECT COUNT(*) FROM custom_raid_scaling WHERE creature_id<>0 AND map_id IN (249,309,409,469) AND NOT ((map_id IN (249,409,469) AND ABS(damage_multiplier-0.40)<0.0001 AND ABS(boss_damage_multiplier-0.40)<0.0001) OR (map_id=309 AND ABS(damage_multiplier-0.45)<0.0001 AND ABS(boss_damage_multiplier-0.45)<0.0001));"

expect_equal \
  "LBRS keeps native creature stats while enabling Blackrock Spire mechanics" \
  1 \
  "SELECT COUNT(*) FROM custom_raid_scaling WHERE map_id=229 AND creature_id=0 AND health_multiplier=1 AND damage_multiplier=1;"

expect_equal \
  "UBRS creatures have explicit five-character scaling" \
  26 \
  "SELECT COUNT(*) FROM custom_raid_scaling WHERE map_id=229 AND creature_id<>0 AND calibration_players=5 AND ABS(health_multiplier-0.55)<0.0001 AND ABS(damage_multiplier-0.55)<0.0001 AND ABS(boss_damage_multiplier-0.55)<0.0001;"

expect_equal \
  "pre-cutoff world bosses use the safer damage ceiling" \
  10 \
  "SELECT COUNT(*) FROM custom_raid_scaling WHERE ((map_id=0 AND creature_id=12397) OR (map_id=1 AND creature_id=6109) OR (map_id IN (0,1) AND creature_id IN (14887,14888,14889,14890))) AND ABS(damage_multiplier-0.40)<0.0001 AND ABS(boss_damage_multiplier-0.40)<0.0001;"

expect_equal \
  "the Brazier of Madness starts one random relay" \
  1 \
  "SELECT COUNT(*) FROM dbscripts_on_go_template_use WHERE id=180327 AND command=45 AND datalong=0 AND datalong2=999904 AND condition_id=0;"

expect_equal \
  "all four Edge of Madness bosses are equally eligible" \
  4 \
  "SELECT COUNT(*) FROM dbscript_random_templates WHERE id=999904 AND type=1 AND target_id IN (99990401,99990402,99990403,99990404) AND chance=0;"

expect_equal \
  "each Edge of Madness choice summons exactly one boss" \
  4 \
  "SELECT IF(COUNT(*)=4 AND COUNT(DISTINCT id)=4 AND COUNT(DISTINCT datalong)=4,4,0) FROM dbscripts_on_relay WHERE id IN (99990401,99990402,99990403,99990404) AND command=10 AND datalong IN (15082,15083,15084,15085) AND condition_id=0;"

expect_equal \
  "the Edge of Madness calendar rotation is absent" \
  0 \
  "SELECT COUNT(*) FROM game_event WHERE entry IN (29,30,31,32);"

expect_equal \
  "the retired Edge of Madness event conditions are absent" \
  0 \
  "SELECT COUNT(*) FROM conditions WHERE condition_entry IN (6029,6030,6031,6032);"

expect_equal \
  "representative post-cutoff raid quests have no quest givers" \
  0 \
  "SELECT (SELECT COUNT(*) FROM creature_questrelation WHERE quest IN (8286,8743,9121,9250)) + (SELECT COUNT(*) FROM gameobject_questrelation WHERE quest IN (8286,8743,9121,9250));"

echo "Classic 1.8.4 cutoff and five-character raid policy validated."
