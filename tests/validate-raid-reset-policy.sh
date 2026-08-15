#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "usage: $0 PATCHED_CORE_TREE" >&2
  exit 64
fi

core_tree=$1
player_cpp="$core_tree/src/game/Entities/Player.cpp"
unit_cpp="$core_tree/src/game/Entities/Unit.cpp"
group_cpp="$core_tree/src/game/Groups/Group.cpp"
map_cpp="$core_tree/src/game/Maps/Map.cpp"
state_cpp="$core_tree/src/game/Maps/MapPersistentStateMgr.cpp"
world_cpp="$core_tree/src/game/World/World.cpp"
config_file="$core_tree/src/mangosd/mangosd.conf.dist.in"

for file in "$player_cpp" "$unit_cpp" "$group_cpp" "$map_cpp" "$state_cpp" "$world_cpp" "$config_file"; do
  if [[ ! -f "$file" ]]; then
    echo "missing patched core file: $file" >&2
    exit 1
  fi
done

rg -Fq '"Custom.Raid.DungeonLikeResets", false' "$world_cpp"
rg -Fq 'Custom.Raid.DungeonLikeResets = 0' "$config_file"

# Boss kills must not create permanent player/group binds under the policy.
rg -Fq '!sWorld.getConfig(CONFIG_BOOL_CUSTOM_RAID_DUNGEON_LIKE_RESETS)' "$unit_cpp"
rg -Fq 'PermBindAllPlayers(creditedPlayer)' "$unit_cpp"

# Solo players and groups must both be allowed to use Reset All Instances.
rg -Fq 'entry->map_type == MAP_RAID &&' "$player_cpp"
rg -Fq '!sWorld.getConfig(CONFIG_BOOL_CUSTOM_RAID_DUNGEON_LIKE_RESETS)' "$player_cpp"
rg -Fq 'entry->map_type == MAP_RAID &&' "$group_cpp"
rg -Fq '!sWorld.getConfig(CONFIG_BOOL_CUSTOM_RAID_DUNGEON_LIKE_RESETS)' "$group_cpp"

# Empty raids use the same per-instance reset scheduler as normal dungeons.
rg -Fq '(!IsRaid() || sWorld.getConfig(CONFIG_BOOL_CUSTOM_RAID_DUNGEON_LIKE_RESETS))' "$map_cpp"
rg -Fq 'DungeonResetEvent(RESET_EVENT_NORMAL_DUNGEON, GetId(), GetInstanceId())' "$map_cpp"
rg -Fq 'mapEntry->map_type == MAP_RAID &&' "$state_cpp"
rg -Fq '!sWorld.getConfig(CONFIG_BOOL_CUSTOM_RAID_DUNGEON_LIKE_RESETS)' "$state_cpp"

# Existing weekly saves are preserved, made non-permanent, and individually timed.
rg -Fq 'SELECT id, map FROM instance WHERE resettime = 0' "$state_cpp"
rg -Fq 'UPDATE instance SET resettime = ' "$state_cpp"
rg -Fq 'UPDATE character_instance SET permanent = 0 WHERE instance = ' "$state_cpp"
rg -Fq 'UPDATE group_instance SET permanent = 0 WHERE instance = ' "$state_cpp"
rg -Fq 'DELETE FROM instance_reset WHERE mapid = ' "$state_cpp"
rg -Fq 'mapEntry->IsRaid() && sWorld.getConfig(CONFIG_BOOL_CUSTOM_RAID_DUNGEON_LIKE_RESETS)' "$state_cpp"

# The normal-dungeon hourly entry tracker remains non-raid-only, so raid farming
# does not acquire a hidden hourly cap while weekly lockouts are removed.
lock_status_body=$(
  awk '
    /AreaLockStatus Player::GetAreaTriggerLockStatus/ { capture = 1 }
    capture { print }
    capture && /^};$/ { exit }
  ' "$player_cpp"
)
rg -Fq 'if (mapEntry->IsNonRaidDungeon())' <<<"$lock_status_body"

echo "Dungeon-like raid resets, legacy-save conversion, and uncapped raid entry validated."
