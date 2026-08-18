#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ $# -ne 3 ]]; then
  echo "usage: $0 CORE_REPOSITORY DATABASE_REPOSITORY PLAYERBOTS_REPOSITORY" >&2
  exit 64
fi

core_source=$1
database_source=$2
playerbots_source=$3

for name in core database playerbots; do
  source_var="${name}_source"
  source_dir=${!source_var}
  case "$name" in
    core) expected_revision=1b3795fcd824338938bb67a0be79cafd26231065 ;;
    database) expected_revision=250a705a462c1acb457d3002359c7e0052c4dafe ;;
    playerbots) expected_revision=21af55995bebd84bc3154730f0e69dc964e3753f ;;
  esac
  actual_revision=$(git -C "$source_dir" rev-parse HEAD)
  if [[ "$actual_revision" != "$expected_revision" ]]; then
    echo "$name is at $actual_revision; expected $expected_revision" >&2
    exit 1
  fi
done

work_dir=$(mktemp -d "${TMPDIR:-/tmp}/cmangos-patch-validation.XXXXXX")
trap 'rm -rf "$work_dir"' EXIT

git clone --quiet --shared "$core_source" "$work_dir/core"
git clone --quiet --shared "$database_source" "$work_dir/database"
git clone --quiet --shared "$playerbots_source" "$work_dir/playerbots"

"$repo_root/docker/apply-patches.sh" \
  "$repo_root/patches" classic \
  "$work_dir/core" "$work_dir/database" "$work_dir/playerbots" \
  1 local

git -C "$work_dir/core" diff --check
git -C "$work_dir/database" diff --check
git -C "$work_dir/playerbots" diff --check

test -f "$work_dir/core/src/game/Globals/CustomRaidScaling.cpp"
test -f "$work_dir/database/Updates/9997_five_character_raid_scaling.sql"
test -f "$work_dir/database/Updates/9998_disable_post_1_8_4_progression.sql"
test -f "$work_dir/database/Updates/9999_custom_01_five_character_instance_caps.sql"
test -f "$work_dir/database/Updates/9999_custom_02_tiered_raid_tuning.sql"
test -f "$work_dir/database/Updates/9999_custom_03_lower_raid_damage.sql"
test -f "$work_dir/database/Updates/9999_custom_04_random_edge_of_madness.sql"
test -f "$work_dir/database/Updates/9999_custom_05_conservative_raid_scaling.sql"
test -f "$work_dir/database/Updates/Instances/999_disable_post_1_8_4_raids.sql"
test -f "$work_dir/playerbots/playerbot/strategy/generic/ZulGurubDungeonStrategies.h"

rg -q 'Custom\.RaidScaling\.TargetPlayers' "$work_dir/core/src/mangosd/mangosd.conf.dist.in"
rg -q 'boss_health_multiplier, boss_damage_multiplier' "$work_dir/core/src/game/Globals/CustomRaidScaling.cpp"
rg -q 'creatureDealer->IsWorldBoss' "$work_dir/core/src/game/Entities/Unit.cpp"
rg -Fq 'GetMechanicCount(instance->GetId(), MAX_STADIUM_MOBS_PER_WAVE, 3)' "$work_dir/core/src/game/AI/ScriptDevAI/scripts/eastern_kingdoms/blackrock_spire/instance_blackrock_spire.cpp"
rg -Fq 'MAX_EGGS_DEFENDERS          = 1' "$work_dir/core/src/game/AI/ScriptDevAI/scripts/eastern_kingdoms/blackwing_lair/blackwing_lair.h"
rg -Fq 'GetMechanicCount(instance->GetId(), MAX_DRAKONID_SUMMONS, 6)' "$work_dir/core/src/game/AI/ScriptDevAI/scripts/eastern_kingdoms/blackwing_lair/blackwing_lair.cpp"
rg -Fq 'AddCombatAction(VAEL_BURNING_ADRENALINE_TANK, true)' "$work_dir/core/src/game/AI/ScriptDevAI/scripts/eastern_kingdoms/blackwing_lair/boss_vaelastrasz.cpp"
! rg -q 'ResetCombatAction\(NEFARIAN_CLASS_CALL' "$work_dir/core/src/game/AI/ScriptDevAI/scripts/eastern_kingdoms/blackwing_lair/boss_nefarian.cpp"
! rg -q 'modifyThreatPercent\(target, -50\)' "$work_dir/core/src/game/AI/ScriptDevAI/scripts/eastern_kingdoms/blackwing_lair/boss_"{firemaw,ebonroc,flamegor}.cpp
rg -q 'WHERE `map` IN \(509, 531, 533\)' "$work_dir/database/Updates/9998_disable_post_1_8_4_progression.sql"
rg -Fq "(229, 10899, 5, 0.55, 0.70, 0.55, 0.70, 'UBRS Goraluk Anvilcrack');" \
  "$work_dir/database/Updates/9999_custom_02_tiered_raid_tuning.sql"
ubrs_scaling_rows=$(rg -c '^  \(229,' "$work_dir/database/Updates/9999_custom_02_tiered_raid_tuning.sql")
[[ "$ubrs_scaling_rows" -eq 27 ]]
rg -Fq 'WHERE `map_id` IN (249, 409, 469);' \
  "$work_dir/database/Updates/9999_custom_03_lower_raid_damage.sql"
rg -Fq 'SET `damage_multiplier` = 0.55,' \
  "$work_dir/database/Updates/9999_custom_03_lower_raid_damage.sql"
conservative_scaling_sql="$work_dir/database/Updates/9999_custom_05_conservative_raid_scaling.sql"
rg -Fq 'SET `health_multiplier` = 0.10,' "$conservative_scaling_sql"
rg -Fq 'SET `health_multiplier` = 0.15,' "$conservative_scaling_sql"
world_add_scaling_rows=$(rg -c '^  \([01], 15(224|260|261|302), 5, 0.15, 0.30,' "$conservative_scaling_sql")
[[ "$world_add_scaling_rows" -eq 8 ]]
edge_of_madness_sql="$work_dir/database/Updates/9999_custom_04_random_edge_of_madness.sql"
rg -Fq '(180327, 5000, 0, 45, 0, 999904' "$edge_of_madness_sql"
edge_random_choices=$(rg -c '^    \(999904, 1, 999904[1-4], 0,' "$edge_of_madness_sql")
[[ "$edge_random_choices" -eq 4 ]]
edge_boss_summons=$(rg -c '^    \(999904[1-4], 0, 0, 10, 1508[2-5], 259200,' "$edge_of_madness_sql")
[[ "$edge_boss_summons" -eq 4 ]]
while IFS= read -r relay_id; do
  [[ "$relay_id" -le 16777215 ]]
done < <(
  sed -nE \
    's/^    \(([0-9]+), 0, 0, 10, 1508[2-5], 259200,.*/\1/p' \
    "$edge_of_madness_sql"
)
rg -Fq 'DELETE FROM `game_event` WHERE `entry` IN (29, 30, 31, 32);' "$edge_of_madness_sql"
rg -Fq 'DELETE FROM `conditions` WHERE `condition_entry` IN (6029, 6030, 6031, 6032);' "$edge_of_madness_sql"
rg -q 'customRaidTargetPlayers' "$work_dir/playerbots/playerbot/strategy/actions/InviteToGroupAction.cpp"
"$repo_root/tests/validate-honor-policy.sh" "$work_dir/core"
"$repo_root/tests/validate-raid-reset-policy.sh" "$work_dir/core"
rg -Fq 'Custom.Honor.InstantProgression.Enabled = 1' "$repo_root/config/classic/mangosd.conf.example"
rg -Fq 'Custom.Raid.DungeonLikeResets = 1' "$repo_root/config/classic/mangosd.conf.example"

echo "Pinned Classic core, database, and PlayerBots patches apply cleanly."
