# Validation

Run the source-level gate against clean checkouts at the pinned revisions:

```sh
tests/validate-patches.sh /path/to/mangos-classic /path/to/classic-db /path/to/playerbots
```

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

The live gate proves that the retained raids remain addressable, the three
post-cutoff raids and their spawns are absent, the launch events are disabled,
and every retained raid/world-boss family has a scaling policy.

A complete `mangosd` startup needs DBC, map, vmap, and mmap data extracted from
a legally obtained 1.12.1 client. Once those files are mounted and the full
stack is up, verify both the world server and PlayerBots initialization:

```sh
tests/validate-classic-runtime.sh
```

## Five-character encounter qualification

Use one five-character raid for every run (normally one human plus four bots),
with one tank, one healer, and three damage roles unless the case says
otherwise. For every representative encounter, record entry, pull, tank
survival, healer mana, bot positioning and targets, add handling, mechanic
execution, kill, loot, and lockout/progression state.

| Raid | Representative gate | Specific observations |
| ---- | ------------------- | --------------------- |
| Onyxia's Lair | Onyxia | Confirm four first-wave whelps, two-to-three later whelps, ranged positioning during flight, fear recovery, kill, loot, and saved instance. |
| Molten Core | Majordomo and Ragnaros | Confirm the mixed four-add Majordomo pack, crowd control/dispels, three Sons of Flame, submerge/emerge progression, loot, and lockout. |
| Blackwing Lair | Razorgore and Nefarian | Confirm phase transition at eight eggs and ten drakonid kills, orb/add targeting, class-call handling, kill, loot, and instance progression. Separately exercise Suppression Room and Chromaggus dispels. |
| Zul'Gurub | Renataki and Hakkar | Confirm Thousand Blades never targets more than three secondary players, automatic ZG strategy activation, poison handling, add targeting, kill, loot, and lockout. |

Also run Azuregos, Lord Kazzak, and one Dragon of Nightmare in the open world.
Check leash/terrain behavior, tank survival, healer mana, add handling, loot,
and respawn/event state. The numerical policies and build are automated; this
matrix is the required gameplay-balance qualification before calling every
encounter production-balanced.
