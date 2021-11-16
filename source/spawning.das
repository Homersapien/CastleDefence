require math
require daslib/media
require daslib/decs_boost
require misc
require map
require actor
require ai
require movement
require battle

let
    FIRST_WAVE_DELAY = 5.0
    WAVES_PERIOD = 20.0
    ENEMIES_PER_WAVE = 7
    NEXT_WAVE_MULTIPLIER = 1.2

[decs_template]
struct EnemiesSpawner
    waves_period: float
    time_to_next_wave: float
    enemies_per_wave: int
    next_wave_multiplier: float

def reset_enemy_spawning()
    create_entity <| @ ( eid, cmp )
        apply_decs_template(cmp, [[EnemiesSpawner
            waves_period = WAVES_PERIOD,
            time_to_next_wave = FIRST_WAVE_DELAY,
            enemies_per_wave = ENEMIES_PER_WAVE,
            next_wave_multiplier = NEXT_WAVE_MULTIPLIER
        ]])

[decs(stage = updating)]
def update_enemy_spawning(var spawner: EnemiesSpawner)
    spawner.time_to_next_wave -= get_delta_time();
    if spawner.time_to_next_wave <= 0.0
        spawner.time_to_next_wave += spawner.waves_period
        spawn_wave(spawner.enemies_per_wave)
        spawner.enemies_per_wave = roundi(float(spawner.enemies_per_wave) * spawner.next_wave_multiplier)

def spawn_wave(count: int)
    for _ in range(count)
        var attempt = 0
        let max_attempts = 20
        var cell = random_border_cell_coordinates(map)
        while cell_is_occupied(cell) && attempt < max_attempts
            ++attempt
            cell = random_border_cell_coordinates(map)
        
        spawn_actor(
            cell_world_center(map, cell),
            0.5,
            1.0,
            100.0,
            [[
                MeleeWeapon
                damage = 25.0,
                rate = 1.0
            ]])

def spawn_actor(position: float2; size: float; speed: float; health: float; var weapon: MeleeWeapon)
    
    let cell_coordinates = world_position_cell_coordinates(map, position)
    find_path_to_keep_once(map, cell_coordinates)

    weapon.attack_period = rate_to_period(weapon.rate)
    
    var entity_id = create_entity <| @ ( eid, cmp )
        cmp |> set ( "eid", eid )
        apply_decs_template(cmp, [[Actor
            position = position,
            size = size,
            faction = Faction Attackers
        ]])
        apply_decs_template(cmp, [[Movement
            velocity = float2(0.0, 0.0),
            target_position = position,
            max_speed = speed,
            cell_index = cell_index(map, cell_coordinates)
        ]])
        apply_decs_template(cmp, [[Behavior
            state = BehaviorState Walking,
            start_cell_index = cell_index(map, cell_coordinates)
        ]])
        apply_decs_template(cmp, [[Health
            value = health,
            max_value = health
        ]])
        apply_decs_template(cmp, weapon)
    push(actors_ids, entity_id)

def spawn_keep(position: float2; size: float; health: float)
    var entity_id = create_entity <| @ ( eid, cmp )
        cmp |> set ("eid", eid)
        apply_decs_template(cmp, [[Actor
            position = position,
            size = size,
            faction = Faction Defenders
        ]])
        apply_decs_template(cmp, [[Health
            value = health,
            max_value = health
        ]])
    keep_id = entity_id

    on_entity_entered_cell(entity_id, position)