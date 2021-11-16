require math
require daslib/media
require daslib/decs_boost
require misc
require map
require actor

[decs_template(prefix = "movement_")]
struct Movement
    velocity: float2
    max_speed: float
    target_position: float2
    cell_index: int

[decs(stage = movement)]
def move_actors(eid: EntityId; var actor: Actor; var movement: Movement)
    
    let delta_time = get_delta_time()

    let vector_to_target = movement.target_position - actor.position
    let direction = normalize(vector_to_target)
    
    let distance = length(vector_to_target)
    let max_speed = distance / delta_time
    var desired_velocity = direction * min(movement.max_speed, max_speed)

    movement.velocity = approach(
        movement.velocity,
        desired_velocity,
        delta_time,
        0.2)

    actor.position += movement.velocity * delta_time

    let current_cell_index = cell_index(map, world_position_cell_coordinates(map, actor.position))
    if current_cell_index != movement.cell_index
        on_entity_left_cell(eid, movement.cell_index)
        movement.cell_index = current_cell_index
        on_entity_entered_cell(eid, current_cell_index)

def stop_actor(actor_id: EntityId)
    update_entity(actor_id) <| @ (eidd, cmp)
        var position = float2(0.0, 0.0)
        position = get(cmp, "actor_position", position)
        set(cmp, "movement_target_position", position)
        set(cmp, "movement_velocity", float2(0.0, 0.0))