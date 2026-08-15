# Validation

Run the source-level gate against clean checkouts at the pinned revisions:

```sh
tests/validate-patches.sh /path/to/mangos-classic /path/to/classic-db /path/to/playerbots
```

This gate also verifies the instant-honor source weights, full-value PlayerBots,
daily per-target diminishing returns, immediate rank-point storage, rank floor,
and removal of weekly maintenance from the enabled policy.

After building the server image, verify that the executable starts and that
the pinned binary contains the PlayerBots command-line integration:

```sh
tests/validate-server-image.sh
```

After starting the custom Classic Compose stack, run the live database gate:

```sh
cp compose-classic.yaml.example compose-classic.yaml
tests/validate-classic-world.sh
```

The live gate proves that every active finite-sized dungeon and retained raid
has a five-character cap, the three post-cutoff raids and their spawns are
absent, the launch events are disabled, every retained raid/world-boss family
has a scaling policy, Lower Blackrock Spire keeps native tuning, and the Upper
Blackrock Spire entries have explicit five-character tuning.

A complete `mangosd` startup needs DBC, map, vmap, and mmap data extracted from
a legally obtained 1.12.1 client. Once those files are mounted and the full
stack is up, verify both the world server and PlayerBots initialization:

```sh
tests/validate-classic-runtime.sh
```

## Five-character encounter qualification

Use one five-character group for every run (normally one human plus four bots),
with one tank, one healer, and three damage roles unless the case says
otherwise. For every representative encounter, record entry, pull, tank
survival, healer mana, bot positioning and targets, add handling, mechanic
execution, kill, loot, and lockout/progression state.

| Instance | Representative gate | Specific observations |
| -------- | ------------------- | --------------------- |
| Upper Blackrock Spire | Emberseer, Rend, and Drakkisath | Confirm four active incarcerators, three active Stadium enemies per wave, four Flamewreath waves, boss/guard targeting, kill, loot, and saved instance. Also confirm a Lower Blackrock Spire run retains native creature strength. |
| Onyxia's Lair | Onyxia | Confirm four first-wave whelps, two-to-three later whelps, ranged positioning during flight, fear recovery, kill, loot, and saved instance. |
| Molten Core | Majordomo and Ragnaros | Confirm the mixed four-add Majordomo pack, crowd control/dispels, three Sons of Flame, submerge/emerge progression, loot, and lockout. |
| Blackwing Lair | Razorgore and Nefarian | Confirm phase transition at eight eggs and ten drakonid kills, orb/add targeting, class-call handling, kill, loot, and instance progression. Separately exercise Suppression Room and Chromaggus dispels. |
| Zul'Gurub | Renataki and Hakkar | Confirm Thousand Blades never targets more than three secondary players, automatic ZG strategy activation, poison handling, add targeting, kill, loot, and lockout. |

For the solo calibration, use a geared level-60 character without bots and pull
one representative elite at a time in Upper Blackrock Spire, Onyxia's Lair,
Zul'Gurub, Molten Core, and Blackwing Lair. Record time to kill, incoming damage,
consumables, cooldowns, and remaining health/resources. The target is a slow but
repeatable isolated kill, not solo completion of a pack, event, or boss. Run a
normal five-character clear as the companion check so the solo baseline does
not make group progression trivial.

For damage safety, record the largest single hit in each representative pull.
An unavoidable boss attack must not kill its correctly geared intended target
from full health or leave the healer without a practical reaction window, and
unavoidable group damage must not one-shot a geared non-tank. Clearly avoidable
failed mechanics may remain lethal. Effects implemented as explicit instakills
bypass the general raid-damage multiplier and therefore require a separate
encounter-specific check.

Also run Azuregos, Lord Kazzak, and one Dragon of Nightmare in the open world.
Check leash/terrain behavior, tank survival, healer mana, add handling, loot,
and respawn/event state. The numerical policies and build are automated; this
matrix is the required gameplay-balance qualification before calling every
encounter production-balanced.

## Instant honor runtime qualification

Use a non-GM character and two enemy PlayerBots of comparable level. Record the
honor bar before and after each kill; do not use GM honor commands during a
case. Run the outdoor sequence against one bot five times on the same server
day and confirm awards of 100%, 75%, 50%, 25%, and 0% of the first award. Kill
the second bot and confirm that it starts at 100%.

Repeat the sequence in a Battleground and confirm that the first comparable
kill grants one fifth of the outdoor progress. Confirm Battleground objective
honor uses the same lower rate, and that no PlayerBot-specific discount is
applied. When honor is shared by a group, verify the existing group split first,
then apply the same source rate and per-character target history expectations.

Finally, restart the world server during the same server day and confirm the
next kill of the first bot retains its diminishing-return position. After the
server date changes, confirm the same target starts at 100% again. Cross the
15-kill and 2,000-point boundaries and verify the title and honor bar update
without waiting for weekly maintenance. If dishonorable kills are exercised,
confirm they can reduce progress to the floor of the highest rank attained but
cannot demote the character with the supplied configuration.
