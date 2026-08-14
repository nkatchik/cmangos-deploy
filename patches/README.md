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
