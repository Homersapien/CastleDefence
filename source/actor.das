require math
require daslib/media
require daslib/decs_boost
require misc
require map

var actors_ids: array<EntityId>
var keep_id: EntityId

enum Faction
    Defenders
    Attackers

[decs_template]
struct Actor
    position: float2
    size: float
    faction: Faction
    attacked_entity_id: EntityId