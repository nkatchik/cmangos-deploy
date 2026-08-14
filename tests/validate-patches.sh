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
test -f "$work_dir/database/Updates/Instances/999_disable_post_1_8_4_raids.sql"
test -f "$work_dir/playerbots/playerbot/strategy/generic/ZulGurubDungeonStrategies.h"

rg -q 'Custom\.RaidScaling\.TargetPlayers' "$work_dir/core/src/mangosd/mangosd.conf.dist.in"
rg -q 'boss_health_multiplier, boss_damage_multiplier' "$work_dir/core/src/game/Globals/CustomRaidScaling.cpp"
rg -q 'creatureDealer->IsWorldBoss' "$work_dir/core/src/game/Entities/Unit.cpp"
rg -q 'WHERE `map` IN \(509, 531, 533\)' "$work_dir/database/Updates/9998_disable_post_1_8_4_progression.sql"
rg -q 'customRaidTargetPlayers' "$work_dir/playerbots/playerbot/strategy/actions/InviteToGroupAction.cpp"
"$repo_root/tests/validate-honor-policy.sh" "$work_dir/core"
rg -Fq 'Custom.Honor.InstantProgression.Enabled = 1' "$repo_root/config/classic/mangosd.conf.example"

echo "Pinned Classic core, database, and PlayerBots patches apply cleanly."
