# CMaNGOS Classic 1.8.4 five-character fork

This is a fork of
[`mserajnik/cmangos-deploy`](https://github.com/mserajnik/cmangos-deploy) for a
specific Classic server: raid progression stops at patch 1.8.4, every active
dungeon and retained raid targets five total characters, PlayerBots are
included, and honor uses immediate personal progression.

Only this fork's differences and the shortest supported startup path are
documented here. For the base deployment's internals, optional services, and
general configuration reference, use the upstream repository.

## What differs from upstream

### Classic content and raids

The deployment builds pinned CMaNGOS Classic, Classic-DB, and PlayerBots source
locally and applies the patches stored in [`patches/classic`](patches/classic).
No external patch repository is required.

- Molten Core, Onyxia's Lair, Blackwing Lair, Zul'Gurub, Azuregos, Lord Kazzak,
  and the four Dragons of Nightmare are retained.
- Ruins of Ahn'Qiraj, Temple of Ahn'Qiraj, Naxxramas, their entrances and
  spawns, and directly dependent progression are disabled because they were
  released after 1.8.4.
- Every active dungeon and retained raid accepts at most five total characters.
  Native five-player dungeons keep their normal creature tuning; Upper
  Blackrock Spire receives explicit five-player creature and event tuning
  without weakening Lower Blackrock Spire.
- A normal group is one human and four bots, converted to a raid when the
  instance requires it.
- Raid instances have no weekly lockout. Once everyone leaves, the leader can
  use **Reset All Instances** and immediately begin a fresh run, just like a
  normal dungeon; existing weekly saves are converted on the first restart.
- The default PlayerBots role template is one tank, one healer, and three DPS.
- Raid-trash and boss health and damage budgets are independently data-driven
  across every retained raid. The trash baseline targets a slow but feasible
  isolated elite kill for a geared level-60 character; packs and bosses remain
  five-character content.
- Encounter overrides cover roster-bound mechanics such as Upper Blackrock
  Spire's event waves, Onyxia's whelps, Ragnaros's sons, Razorgore's eggs, and
  Nefarian's phase-one kill count.

The supplied tuning is a starting calibration, not a claim that every group
composition has completed live balance testing. See
[`tests/README.md`](tests/README.md) for the qualification matrix.

### Honor progression

Weekly standings, brackets, recalculation, and decay are replaced with
immediate permanent rank-point gains.

| Source | Multiplier |
| ------ | ---------: |
| World PvP player or PlayerBot kill | `0.5` |
| Battleground player or PlayerBot kill | `0.1` |
| Battleground objective or bonus | `0.1` |

PlayerBots count as ordinary player opponents. Repeated kills of the same
target on one server day award 100%, 75%, 50%, 25%, then 0%. Rank 1 requires
15 lifetime honorable kills; Rank 2 starts at 2,000 points, later ranks use
5,000-point steps, and Rank 14 starts at 60,000. Dishonorable kills cannot
remove the highest rank already attained by default.

The defaults are in
[`config/classic/mangosd.conf.example`](config/classic/mangosd.conf.example).

## Quick start

You need Docker with Compose V2 and a legally obtained WoW Classic 1.12.1
client. The server uses the 1.12.1 client and data model while enforcing the
1.8.4 raid-content policy on the server.

### 1. Clone and create the working configuration

```sh
git clone https://github.com/nkatchik/cmangos-deploy.git
cd cmangos-deploy

cp compose-classic.yaml.example compose.yaml
cp config/classic/mangosd.conf.example config/classic/mangosd.conf
cp config/classic/realmd.conf.example config/classic/realmd.conf
cp config/classic/ahbot.conf.example config/classic/ahbot.conf
cp config/classic/aiplayerbot.conf.example config/classic/aiplayerbot.conf
cp config/classic/anticheat.conf.example config/classic/anticheat.conf
cp config/classic/mods.conf.example config/classic/mods.conf
```

Before first start, edit `compose.yaml`:

- Set `CMANGOS_REALMLIST_ADDRESS` to `127.0.0.1` for same-machine play, the
  server's LAN address for LAN play, or its public DNS name/address for Internet
  play.
- Set `TZ` as desired.
- On Linux, if `id -u` or `id -g` is not `1000`, change both `user: 1000:1000`
  entries to your UID and GID.
- Change database passwords if desired. If `MARIADB_USER` or
  `MARIADB_PASSWORD` changes, update the four database connection strings in
  `config/classic/mangosd.conf` and `config/classic/realmd.conf` to match.

Random world bots are disabled by default to avoid unexpectedly creating
1,000 bots. To populate the world, edit `config/classic/aiplayerbot.conf`, set
`AiPlayerbot.RandomBotAutologin = 1`, and choose hardware-appropriate
`AiPlayerbot.MinRandomBots` and `AiPlayerbot.MaxRandomBots` values first.

### 2. Build the custom images

```sh
docker compose build database realmd
```

This compiles the pinned patched server and prepares the patched Classic
database image. `mangosd` and `realmd` share the same server image.

### 3. Extract the required client data

Copy the complete 1.12.1 client into
`storage/classic/mangosd/client-data/`. The resulting path must contain the
client's `Data/` directory. Then run:

```sh
docker run -i --rm \
  --user "$(id -u):$(id -g)" \
  -v "$PWD/storage/classic/mangosd/client-data:/opt/cmangos/storage/client-data:ro" \
  -v "$PWD/storage/classic/mangosd/extracted-data:/opt/cmangos/storage/data" \
  cmangos-custom-server-classic:1.8.4-five-character \
  extract-client-data
```

Extraction can take several hours. It is complete when `dbc/`, `maps/`,
`mmaps/`, and `vmaps/` exist under
`storage/classic/mangosd/extracted-data/`.

### 4. Start the server

```sh
docker compose up -d
docker compose logs -f mangosd
```

The first database import and initial PlayerBots setup can take a while. Do not
stop the stack during the initial import. The world is ready when the log shows
`CMANGOS: World initialized`.

Create an account through the world-server console:

```sh
docker compose attach mangosd
```

Then enter:

```text
account create <name> <password>
account set gmlevel <name> 3
```

Level `3` is administrator; use `0` for a normal player account. Detach without
stopping the server with <kbd>Ctrl</kbd>+<kbd>P</kbd>, then
<kbd>Ctrl</kbd>+<kbd>Q</kbd>.

In the client's `realmlist.wtf`, use the same address configured above:

```text
set realmlist <server-address>
```

## Network access

For Internet players, allow and forward these host ports to the server:

| Protocol | Port | Purpose |
| -------- | ---: | ------- |
| TCP | `3724` | Login server |
| TCP | `8085` | World server |

Do not expose MariaDB, phpMyAdmin, SOAP, or RA. The Compose `ports` entries
publish ports on the host, but neither Docker nor CMaNGOS requests router
mapping through UPnP, so router forwarding is not automatic even when UPnP is
enabled. LAN-only and same-machine play require no router forwarding.

## Data, backups, and moving characters

| Data | Location |
| ---- | -------- |
| Accounts, characters, world state, and database metadata | Docker named volume `cmangos-database-classic` |
| Original client files | `storage/classic/mangosd/client-data/` |
| Extracted DBC/maps/vmaps/mmaps | `storage/classic/mangosd/extracted-data/` |
| Server logs | `storage/classic/mangosd/logs/` and `storage/classic/realmd/logs/` |
| Custom world SQL | `storage/classic/database/custom-sql/` |
| Optional backup files | `storage/classic/database/backups/` |

`docker compose down` preserves the named database volume. Do not use
`docker compose down -v` unless you intend to delete every account and
character.

To move players to another server using the same fork and database revisions,
export both `realmd` and `characters`; character rows depend on account IDs in
`realmd`.

```sh
mkdir -p storage/classic/database/backups
docker compose exec -T database sh -c \
  'mariadb-dump -u root -p"$MARIADB_ROOT_PASSWORD" --databases realmd characters' \
  > storage/classic/database/backups/players.sql
```

On the destination, start its database once, copy `players.sql` into the
repository, stop its game services, and restore:

```sh
docker compose stop realmd mangosd
docker compose exec -T database sh -c \
  'mariadb -u root -p"$MARIADB_ROOT_PASSWORD"' \
  < storage/classic/database/backups/players.sql
docker compose start realmd mangosd
```

Back up the destination first. Add the `mangos` database to the dump only if
you also need manual world-database customizations; repeatable customizations
belong in `storage/classic/database/custom-sql/` instead.

## Routine commands

```sh
# Stop without deleting data
docker compose down

# Update this fork and rebuild the pinned custom images
git pull
docker compose build database realmd
docker compose up -d

# Validate the built image
tests/validate-server-image.sh
```

Patch layout and source ownership are described in
[`patches/README.md`](patches/README.md). Licensing remains as recorded in
[`LICENSES/`](LICENSES).
