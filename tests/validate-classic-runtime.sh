#!/usr/bin/env bash

set -euo pipefail

compose_file=${COMPOSE_FILE:-compose-classic.yaml}
server_service=${SERVER_SERVICE:-mangosd}

container_id=$(docker compose -f "$compose_file" ps -q "$server_service")
if [[ -z "$container_id" ]]; then
  echo "$server_service has no Compose container" >&2
  exit 1
fi

running=$(docker inspect --format '{{.State.Running}}' "$container_id")
if [[ "$running" != true ]]; then
  docker compose -f "$compose_file" logs --tail 100 "$server_service" >&2
  exit 1
fi

logs=$(docker compose -f "$compose_file" logs "$server_service")
grep -Fq "Initializing AI Playerbot" <<<"$logs"
grep -Fq "CMANGOS: World initialized" <<<"$logs"

docker compose -f "$compose_file" exec -T "$server_service" nc -z localhost 8085
echo "mangosd is accepting connections and PlayerBots completed initialization."
