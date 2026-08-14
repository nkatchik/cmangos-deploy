#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "usage: $0 PATCHED_CORE_TREE" >&2
  exit 64
fi

core_tree=$1
player_cpp="$core_tree/src/game/Entities/Player.cpp"
formulas_h="$core_tree/src/game/Tools/Formulas.h"
world_cpp="$core_tree/src/game/World/World.cpp"
config_file="$core_tree/src/mangosd/mangosd.conf.dist.in"

for file in "$player_cpp" "$formulas_h" "$world_cpp" "$config_file"; do
  if [[ ! -f "$file" ]]; then
    echo "missing patched core file: $file" >&2
    exit 1
  fi
done

rg -Fq 'static float const repeatedKillRate[4] = {1.0f, 0.75f, 0.5f, 0.25f};' "$formulas_h"
rg -Fq 'if (total_kills >= 4)' "$formulas_h"
rg -Fq 'CalculateTotalKills(victim, today, today)' "$formulas_h"

rg -Fq 'CONFIG_FLOAT_CUSTOM_HONOR_WORLD_PVP_KILL_RATE' "$player_cpp"
rg -Fq 'CONFIG_FLOAT_CUSTOM_HONOR_BATTLEGROUND_KILL_RATE' "$player_cpp"
rg -Fq 'CONFIG_FLOAT_CUSTOM_HONOR_BATTLEGROUND_BONUS_RATE' "$player_cpp"
rg -Fq 'GetStoredHonor() + honor' "$player_cpp"
rg -Fq 'GetHonorHighestRankInfo().visualRank' "$player_cpp"
rg -Fq 'total_honorableKills < sWorld.getConfig(CONFIG_UINT32_MIN_HONOR_KILLS)' "$player_cpp"
rg -Fq 'return float(visualRank - 2) * 5000.0f;' "$player_cpp"

add_honor_body=$(
  awk '
    /bool Player::AddHonorCP/ { capture = 1 }
    capture { print }
    /uint32 Player::GetGuildIdFromDB/ { exit }
  ' "$player_cpp"
)
if rg -qi 'playerbot|bot victim|bot multiplier' <<<"$add_honor_body"; then
  echo "instant honor must not discount PlayerBots" >&2
  exit 1
fi

rg -Fq 'weekly standings and rank distribution are disabled' "$world_cpp"
rg -Fq 'FlushHonorHistory(beforeDate)' "$world_cpp"
rg -Fq 'uint32 beforeDate = today > 14 ? today - 14 : 0;' "$world_cpp"

rg -Fq 'MaxHonorPoints = 75000' "$config_file"
rg -Fq 'MinHonorKills = 15' "$config_file"

world_rate=$(awk '$1 == "Custom.Honor.WorldPvPKillRate" { print $3; exit }' "$config_file")
battleground_rate=$(awk '$1 == "Custom.Honor.BattlegroundKillRate" { print $3; exit }' "$config_file")
awk -v world="$world_rate" -v battleground="$battleground_rate" \
  'BEGIN { if (world != 5 * battleground) exit 1 }'

echo "Instant honor progression, full-value bots, 5:1 source weighting, and daily target DR validated."
