require math
require daslib/media
require daslib/decs_boost
require global
require misc
require map
require entities

[decs_template]
struct Movement
    velocity: float2
    max_speed: float
    target_position: float2
    cell_index: int

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