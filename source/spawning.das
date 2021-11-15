require math
require daslib/media
require daslib/decs_boost
require misc
require map
require actor
require ai
require movement
require battle

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
            1.0 * 3.0,
            100.0,
            [[
                Weapon
                attack_range = 1.0,
                damage = 25.0,
                rate = 1.0
            ]])

def spawn_actor(position: float2; size: float; speed: float; health: float; var weapon: Weapon)
    
    let cell_coordinates = world_position_cell_coordinates(map, position)
    find_path_to_keep_once(map, cell_coordinates)

    weapon.attack_period = weapon.rate > 0.0 ? 1.0 / weapon.rate : FLT_MAX
    
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
    push(map.cells[cell_index(map, world_position_cell_coordinates(map, position))].entitity_ids, entity_id)