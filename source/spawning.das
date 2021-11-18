require math
require daslib/media
require daslib/decs_boost
require misc
require map
require actor
require ai
require movement
require battle
require game_result

let
    FIRST_WAVE_DELAY = 15.0
    WAVES_PERIOD = 30.0
    ENEMIES_PER_WAVE = 5
    SINGLE_ENEMY_SPAWNING_EPRIOD = 0.1
    NEXT_WAVE_MULTIPLIER = 1.3
    WAVES_COUNT = 15

let
    KEEP_HEALTH = 500.0
    ENEMY_WEAPON_DAMAGE = 10.0
    ENEMY_WEAPON_RATE = 1.0
    ENEMY_HEALTH = 100.0
    ENEMY_WALKING_SPEED = 1.0

[decs_template]
struct EnemiesSpawner
    waves_period: float
    time_to_next_wave: float
    enemies_per_wave: int
    spawned_waves_count: int
    next_wave_multiplier: float
    pending_enemies_count: int
    time_to_next_enemy: float

def reset_enemy_spawning()
    create_entity <| @ ( eid, cmp )
        apply_decs_template(cmp, [[EnemiesSpawner
            waves_period = WAVES_PERIOD,
            time_to_next_wave = FIRST_WAVE_DELAY,
            enemies_per_wave = ENEMIES_PER_WAVE,
            spawned_waves_count = 0,
            next_wave_multiplier = NEXT_WAVE_MULTIPLIER,
            pending_enemies_count = 0
        ]])

[decs(stage = updating)]
def update_enemy_spawning(var spawner: EnemiesSpawner)
    
    if spawner.pending_enemies_count > 0
        spawner.time_to_next_enemy -= get_delta_time()
        if spawner.time_to_next_enemy <= 0.0
            spawner.time_to_next_enemy += SINGLE_ENEMY_SPAWNING_EPRIOD
            --spawner.pending_enemies_count
            spawn_wave_single_enemy()

    if spawner.spawned_waves_count < WAVES_COUNT
        
        spawner.time_to_next_wave -= get_delta_time()
        if spawner.time_to_next_wave <= 0.0
            spawner.time_to_next_wave += spawner.waves_period
            spawner.pending_enemies_count += spawner.enemies_per_wave
            ++spawner.spawned_waves_count
            spawner.enemies_per_wave = roundi(float(spawner.enemies_per_wave) * spawner.next_wave_multiplier)
    
    elif length(actors_ids) == 0 && spawner.pending_enemies_count == 0 && game_result == GameResult None
        on_victory()

def spawn_wave_single_enemy()
    var attempt = 0
    let max_attempts = 20
    var cell = random_border_cell_coordinates(map)
    while cell_is_occupied(cell) && attempt < max_attempts
        ++attempt
        cell = random_border_cell_coordinates(map)
    
    spawn_enemy(
        cell_world_center(map, cell),
        0.5,
        ENEMY_WALKING_SPEED,
        ENEMY_HEALTH,
        [[
            MeleeWeapon
            damage = ENEMY_WEAPON_DAMAGE,
            rate = ENEMY_WEAPON_RATE
        ]])

def spawn_enemy(position: float2; size: float; speed: float; health: float; var weapon: MeleeWeapon)
    
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

def spawn_keep(position: float2)
    var entity_id = create_entity <| @ ( eid, cmp )
        cmp |> set ("eid", eid)
        apply_decs_template(cmp, [[Actor
            position = position,
            size = 0.8,
            faction = Faction Defenders
        ]])
        apply_decs_template(cmp, [[Health
            value = KEEP_HEALTH,
            max_value = KEEP_HEALTH
        ]])
    keep_id = entity_id

    on_entity_entered_cell(entity_id, position)