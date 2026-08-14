#!/bin/sh

# SPDX-FileCopyrightText: 2026 Nikita Katchik
# SPDX-License-Identifier: AGPL-3.0-or-later

# Apply the deployment-owned patch sets to checked-out CMaNGOS repositories.
#
# Layout (all directories are optional):
#   <root>/all/{core,database,playerbots}/*.patch
#   <root>/<expansion>/{core,database,playerbots}/*.patch
#
# Legacy external patch repositories are also supported: top-level patch files
# directly below `all/` or `<expansion>/` are treated as core patches.

set -eu

if [ "$#" -ne 7 ]; then
  echo "usage: $0 PATCH_ROOT EXPANSION CORE_DIR DATABASE_DIR PLAYERBOTS_DIR STRICT LABEL" >&2
  exit 64
fi

patch_root=$1
expansion=$2
core_dir=$3
database_dir=$4
playerbots_dir=$5
strict=$6
label=$7
patch_count=0

case "$patch_root" in
  /*) ;;
  *) patch_root=$(cd "$patch_root" && pwd) ;;
esac

# The upstream PlayerBots repository stores its sources with CRLF endings.
# Preserve those endings while applying reviewable text patches on Linux;
# otherwise `git apply` rewrites every touched file and obscures the real diff.
if [ "$playerbots_dir" != "-" ] && [ -d "$playerbots_dir/.git" ]; then
  git -C "$playerbots_dir" config core.autocrlf true
fi

apply_patch_dir() {
  patch_dir=$1
  target=$2

  if [ "$target" = "-" ] || [ ! -d "$patch_dir" ]; then
    return
  fi

  for patch_file in "$patch_dir"/*.patch; do
    if [ ! -f "$patch_file" ]; then
      continue
    fi

    echo "Applying $label patch $patch_file to $target"
    if git -C "$target" apply --check "$patch_file" && git -C "$target" apply "$patch_file"; then
      patch_count=$((patch_count + 1))
      continue
    fi

    echo "Failed to apply $label patch $patch_file to $target" >&2
    if [ "$strict" = "1" ]; then
      exit 1
    fi
  done
}

for scope in all "$expansion"; do
  apply_patch_dir "$patch_root/$scope/core" "$core_dir"
  apply_patch_dir "$patch_root/$scope/database" "$database_dir"
  apply_patch_dir "$patch_root/$scope/playerbots" "$playerbots_dir"

  # Backwards compatibility for the original external patch repository.
  apply_patch_dir "$patch_root/$scope" "$core_dir"
done

if [ "$patch_count" -eq 0 ]; then
  echo "No $label patches found for expansion '$expansion'"
else
  echo "Applied $patch_count $label patch(es) for expansion '$expansion'"
fi
