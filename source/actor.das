require math
require daslib/media
require daslib/decs_boost
require global
require misc
require map

enum Faction
    Defenders
    Attackers

[decs_template]
struct Actor
    position: float2
    size: float
    faction: Faction