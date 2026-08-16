#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

assert_lf_attribute() {
  local relative_path=$1
  local attribute

  attribute=$(git -C "$repo_root" check-attr eol -- "$relative_path")
  [[ "$attribute" == "$relative_path: eol: lf" ]]
}

assert_lf_attribute docker/apply-patches.sh
assert_lf_attribute patches/classic/core/0100-five-character-raid-scaling.patch
assert_lf_attribute docker/database/Dockerfile
assert_lf_attribute docker/server/Dockerfile

for dockerfile in docker/database/Dockerfile docker/server/Dockerfile; do
  rg -Fq "sed -i 's/\\r\$//' /usr/local/bin/apply-cmangos-patches" \
    "$repo_root/$dockerfile"
  rg -Fq "find /build/local-patches -type f -name '*.patch'" \
    "$repo_root/$dockerfile"
done

for runtime_script in \
  /opt/scripts/db-functions.sh \
  /docker-entrypoint-initdb.d/create-db.sh \
  /always-initdb.d/update-db.sh \
  /usr/local/bin/cmangos-healthcheck \
  /usr/local/bin/cmangos-confirm-changes \
  /entrypoint.sh; do
  rg -Fq "$runtime_script" "$repo_root/docker/database/Dockerfile"
done

for runtime_script in \
  /usr/local/bin/mangosd \
  /usr/local/bin/realmd \
  /usr/local/bin/extract-client-data; do
  rg -Fq "$runtime_script" "$repo_root/docker/server/Dockerfile"
done

work_dir=$(mktemp -d "${TMPDIR:-/tmp}/cmangos-crlf-validation.XXXXXX")
trap 'rm -rf "$work_dir"' EXIT

sed 's/$/\r/' "$repo_root/docker/apply-patches.sh" >"$work_dir/apply-patches.sh"
sed -i.bak 's/\r$//' "$work_dir/apply-patches.sh"
rm "$work_dir/apply-patches.sh.bak"

cmp "$repo_root/docker/apply-patches.sh" "$work_dir/apply-patches.sh"
sh -n "$work_dir/apply-patches.sh"

echo "Windows checkout line endings are normalized for Docker builds."
