# Local CMaNGOS patches

The Docker builds apply patches from this directory after checking out the
configured upstream revisions and before compiling or packaging SQL.

Patches under `all/` apply to every expansion. Patches under `classic/` apply
only to the Classic build. Within either scope:

- `core/*.patch` targets the CMaNGOS core checkout;
- `database/*.patch` targets the Classic-DB checkout;
- `playerbots/*.patch` targets the PlayerBots checkout.

Files are applied in lexical order. Local patch failures are always fatal. The
optional external patch-repository build argument remains supported, and its
patches are applied after this hierarchy.

Classic-specific core patches are intentionally split by concern:

- `0100-five-character-raid-scaling.patch` adds data-driven raid scaling;
- `0101-five-character-encounter-mechanics.patch` adjusts roster-bound raid
  mechanics;
- `0102-instant-honor-progression.patch` replaces weekly competitive ranking
  with immediate personal progression, world/Battleground source rates, and
  daily per-target diminishing returns.
