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
  daily per-target diminishing returns;
- `0103-tiered-raid-creature-scaling.patch` gives raid trash and bosses
  independent health and damage budgets;
- `0104-five-character-blackrock-spire-mechanics.patch` reduces the fixed-size
  Upper Blackrock Spire event waves for a five-character group.

The Classic database patches are also split by concern. In particular,
`0103-five-character-instance-caps.patch` caps every active finite-sized
dungeon or raid at five, while `0104-tiered-raid-creature-tuning.patch` sets
the retained-raid tiers and targets Upper Blackrock Spire entries explicitly
so Lower Blackrock Spire stays at native tuning. The follow-up
`0105-lower-five-character-raid-damage.patch` gives raid bosses, world bosses,
and Upper Blackrock Spire a safer dungeon-like per-hit damage ceiling.
