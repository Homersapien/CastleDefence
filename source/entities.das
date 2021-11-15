require math
require misc
require daslib/media
require daslib/decs_boost
require global
require map
require misc

enum Faction
    Defenders
    Attackers

[decs_template]
struct Actor
    position: float2
    size: float
    faction: Faction

[decs_template]
struct Movement
    velocity: float2
    max_speed: float
    target_position: float2
    cell_index: int

enum BehaviorState
    Walking
    Fighting

[decs_template]
struct Behavior
    state: BehaviorState
    start_cell_index: int
    path_step: int = 0
    attacked_entity_id: EntityId

[decs_template]
struct Health
    value: float
    max_value: float

[decs_template]
struct Weapon
    attack_range: float
    damage: float
    rate: float

def on_entity_entered_cell(eid: EntityId; cell_index: int)
    push(map.cells[cell_index].entitity_ids, eid)

def on_entity_left_cell(eid: EntityId; cell_index: int)
    let index = find_index(map.cells[cell_index].entitity_ids, eid)
    if index >= 0
        erase(map.cells[cell_index].entitity_ids, index)

[decs(stage = movement)]
def move_actors(eid: EntityId; var actor: Actor; var movement: Movement)
    let delta_time = get_delta_time()

    var desired_velocity = normalize(movement.target_position - actor.position) * movement.max_speed
    
    movement.velocity = approach(
        movement.velocity,
        desired_velocity,
        delta_time,
        0.3)
    
    actor.position += movement.velocity * get_delta_time()

    let current_cell_index = cell_index(map, world_position_cell_coordinates(map, actor.position))
    if current_cell_index != movement.cell_index
        on_entity_left_cell(eid, movement.cell_index)
        movement.cell_index = current_cell_index
        on_entity_entered_cell(eid, current_cell_index)

def try_find_attackable_enemy(actor_id: EntityId; actor_faction: Faction; actor_cell: int2; var found_id: EntityId) : bool
    if try_find_attackable_enemy_in_single_cell(actor_id, actor_faction, actor_cell, found_id)
        return true
    if try_find_attackable_enemy_in_single_cell(actor_id, actor_faction, actor_cell + int2(1, 0), found_id)
        return true
    if try_find_attackable_enemy_in_single_cell(actor_id, actor_faction, actor_cell + int2(0, 1), found_id)
        return true
    if try_find_attackable_enemy_in_single_cell(actor_id, actor_faction, actor_cell + int2(-1, 0), found_id)
        return true
    if try_find_attackable_enemy_in_single_cell(actor_id, actor_faction, actor_cell + int2(0, -1), found_id)
        return true
    return false

def try_find_attackable_enemy_in_single_cell(actor_id: EntityId; actor_faction: Faction; actor_cell: int2; var found_id: EntityId) : bool
    if cell_coordinate_is_valid(map, actor_cell)
        for id in map.cells[cell_index(map, actor_cell)].entitity_ids
            if id != actor_id
                query(id) <| $ (enemy_actor: Actor)
                    if enemy_actor.faction != actor_faction
                        found_id = id
                return true
    return false

[decs(stage = thinking)]
def think(eid: EntityId; actor: Actor; var behavior: Behavior; var movement: Movement)
    
    // Damaging not implemented yet
    if behavior.state == BehaviorState Fighting
        let target_found = query(behavior.attacked_entity_id) <| $ (health: Health)
            var _ = 1
        if target_found
            return

    let current_cell_coordinates = world_position_cell_coordinates(map, actor.position)
    var attackable_enemy_id : EntityId
    if try_find_attackable_enemy(eid, actor.faction, current_cell_coordinates, attackable_enemy_id)
        behavior.state = BehaviorState Fighting
        behavior.attacked_entity_id = attackable_enemy_id
        
        // Damaging not implemented yet
        query(attackable_enemy_id) <| $ (killed_actor: Actor)
            on_entity_left_cell(attackable_enemy_id, cell_index(map, world_position_cell_coordinates(map, killed_actor.position)))
            delete_entity(attackable_enemy_id)

    behavior.state = BehaviorState Walking
    let path_length = length(map.cells[behavior.start_cell_index].path_to_keep)
    if behavior.path_step + 1 < path_length - 1
        if current_cell_coordinates == world_position_cell_coordinates(map, movement.target_position)
            ++behavior.path_step
            var next_target_cell = map.cells[behavior.start_cell_index].path_to_keep[path_length - behavior.path_step - 1]
            movement.target_position = cell_world_center(map, next_target_cell)

def cell_is_occupied(coordinates: int2)
    return false

def random_border_cell_coordinates(map: Map)
    var index = random_int_in_range(0, map.width * 2 + (map.height - 2) * 2)
    if index < map.width
        return int2(index, 0)
    index -= map.width
    if index < map.width
        return int2(index, map.height - 1)
    index -= map.width
    if index < map.height - 2
        return int2(0, index + 1)
    index -= map.height - 2
    return int2(map.width - 1, index + 1)

def spawn_wave(count: int)
    for _ in range(count)
        var attempt = 0
        let max_attempts = 20
        var cell = random_border_cell_coordinates(map)
        while cell_is_occupied(cell) && attempt < max_attempts
            ++attempt
            cell = random_border_cell_coordinates(map)
        spawn_actor(cell_world_center(map, cell), 0.5, 1.0, 100.0)

def spawn_actor(position: float2; size: float; speed: float; health: float)
    let cell_coordinates = world_position_cell_coordinates(map, position)
    find_path_to_keep_once(map, cell_coordinates)
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
    push(actors_ids, entity_id)

def spawn_keep(position: float2; size: float; health: float)
    var entity_id = create_entity <| @ ( eid, cmp )
        cmp |> set ( "eid", eid )
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