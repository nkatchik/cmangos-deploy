#!/usr/bin/env bash

set -euo pipefail

image=${1:-cmangos-custom-server-classic:1.8.4-five-character}
expected_revision=1b3795fcd824338938bb67a0be79cafd26231065

version_output=$(docker run --rm --entrypoint /opt/cmangos/bin/mangosd "$image" --version)
help_output=$(docker run --rm --entrypoint /opt/cmangos/bin/mangosd "$image" --help)

grep -Fq "$expected_revision" <<<"$version_output"
grep -Fq -- "--aiplayerbot" <<<"$help_output"

echo "$version_output"
echo "Custom mangosd executable starts and exposes the compiled PlayerBots module."
