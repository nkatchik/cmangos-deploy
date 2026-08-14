# SPDX-FileCopyrightText: 2026 Michael Serajnik <https://github.com/mserajnik>
# SPDX-License-Identifier: AGPL-3.0-or-later

ARG DEBIAN_FRONTEND=noninteractive
ARG CMANGOS_EXPANSION=classic
ARG CMANGOS_CORE_REPOSITORY_URL=https://github.com/cmangos/mangos-classic.git
ARG CMANGOS_CORE_REVISION=1b3795fcd824338938bb67a0be79cafd26231065
ARG CMANGOS_DATABASE_REPOSITORY_URL=https://github.com/cmangos/classic-db.git
ARG CMANGOS_DATABASE_REVISION=250a705a462c1acb457d3002359c7e0052c4dafe
ARG CMANGOS_PLAYERBOTS_REPOSITORY_URL=https://github.com/cmangos/playerbots.git
ARG CMANGOS_PLAYERBOTS_REVISION=21af55995bebd84bc3154730f0e69dc964e3753f
ARG CMANGOS_PATCHES_REPOSITORY_URL
ARG CMANGOS_FAIL_ON_PATCH_ERROR=0
ARG CMANGOS_MIGRATION_EDITS=

FROM mariadb:12.3 AS build

ARG DEBIAN_FRONTEND
ARG CMANGOS_EXPANSION
ARG CMANGOS_CORE_REPOSITORY_URL
ARG CMANGOS_CORE_REVISION
ARG CMANGOS_DATABASE_REPOSITORY_URL
ARG CMANGOS_DATABASE_REVISION
ARG CMANGOS_PLAYERBOTS_REPOSITORY_URL
ARG CMANGOS_PLAYERBOTS_REVISION
ARG CMANGOS_PATCHES_REPOSITORY_URL
ARG CMANGOS_FAIL_ON_PATCH_ERROR

COPY --chmod=755 ./docker/apply-patches.sh /usr/local/bin/apply-cmangos-patches
COPY ./patches /build/local-patches

RUN \
  apt update && \
  apt install -y --no-install-recommends \
    git && \
  git clone "$CMANGOS_CORE_REPOSITORY_URL" /build/core && \
  git clone "$CMANGOS_DATABASE_REPOSITORY_URL" /build/database && \
  git clone "$CMANGOS_PLAYERBOTS_REPOSITORY_URL" /build/playerbots && \
  cd /build/core && \
  git checkout "$CMANGOS_CORE_REVISION" && \
  cd /build/database && \
  git checkout "$CMANGOS_DATABASE_REVISION" && \
  cd /build/playerbots && \
  git checkout "$CMANGOS_PLAYERBOTS_REVISION" && \
  apply-cmangos-patches \
    /build/local-patches \
    "$CMANGOS_EXPANSION" \
    /build/core \
    /build/database \
    /build/playerbots \
    1 \
    local && \
  if [ -n "$CMANGOS_PATCHES_REPOSITORY_URL" ]; then \
    echo "Cloning and applying patches from $CMANGOS_PATCHES_REPOSITORY_URL"; \
    git clone "$CMANGOS_PATCHES_REPOSITORY_URL" /build/patches && \
    apply-cmangos-patches \
      /build/patches \
      "$CMANGOS_EXPANSION" \
      /build/core \
      /build/database \
      /build/playerbots \
      "$CMANGOS_FAIL_ON_PATCH_ERROR" \
      external; \
  else \
    echo "No external patch repository provided"; \
  fi && \
  mkdir -p /sql/core /sql/custom /sql/database /sql/playerbots && \
  cp -a /build/core/sql/base /sql/core/base && \
  cp -a /build/core/sql/updates /sql/core/updates && \
  cp -a /build/core/sql/scriptdev2 /sql/core/scriptdev2 && \
  cp -a /build/database/Full_DB /sql/database/Full_DB && \
  cp -a /build/database/Updates /sql/database/Updates && \
  cp -a /build/database/ACID /sql/database/ACID && \
  cp -a /build/database/utilities /sql/database/utilities && \
  cp -a /build/database/locales /sql/database/locales && \
  cp -a /build/playerbots/sql /sql/playerbots/sql

FROM mariadb:12.3

ARG CMANGOS_EXPANSION
ARG CMANGOS_MIGRATION_EDITS

# See https://github.com/MariaDB/mariadb-docker/blob/f8552c80b5104868ff1bb88851ca976bd99029ee/12.3/docker-entrypoint.sh#L595-L599
ENV MARIADB_AUTO_UPGRADE=1
ENV MARIADB_USER=mangos
ENV MARIADB_PASSWORD=mangos
ENV MARIADB_ROOT_PASSWORD=password
ENV CMANGOS_REALMLIST_NAME=CMaNGOS
ENV CMANGOS_REALMLIST_ADDRESS=127.0.0.1
ENV CMANGOS_REALMLIST_PORT=8085
ENV CMANGOS_REALMLIST_ICON=1
ENV CMANGOS_REALMLIST_TIMEZONE=0
ENV CMANGOS_REALMLIST_ALLOWED_SECURITY_LEVEL=0
ENV CMANGOS_EXPANSION=$CMANGOS_EXPANSION
ENV CMANGOS_ENABLE_AUTOMATIC_WORLD_DB_CORRECTIONS=1
ENV CMANGOS_HALT_ON_MIGRATION_EDITS=1
ENV CMANGOS_PROCESS_CUSTOM_SQL=1

COPY --from=build /sql /sql

RUN \
  mkdir -p /opt/scripts && \
  mkdir /always-initdb.d && \
  printf '%s\n' "$CMANGOS_MIGRATION_EDITS" >/sql/migration-edits

COPY ./docker/database/db-functions.sh /opt/scripts
COPY --chmod=755 ./docker/database/create-db.sh /docker-entrypoint-initdb.d
COPY --chmod=755 ./docker/database/update-db.sh /always-initdb.d
COPY --chmod=755 ./docker/database/healthcheck.sh /usr/local/bin/cmangos-healthcheck
COPY --chmod=755 ./docker/database/cmangos-confirm-changes.sh /usr/local/bin/cmangos-confirm-changes

COPY --chmod=755 ./docker/database/docker-entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["mariadbd"]
