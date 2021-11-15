require math
require daslib/media
require daslib/decs_boost
require global
require misc
require map

[decs_template]
struct Health
    value: float
    max_value: float

[decs_template]
struct Weapon
    attack_range: float
    damage: float
    rate: float