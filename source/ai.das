require math
require daslib/media
require daslib/decs_boost
require misc
require map
require actor
require movement

enum BehaviorState
    Walking
    Fighting

[decs_template]
struct Behavior
    state: BehaviorState
    start_cell_index: int
    path_step: int = 0

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
                found_id = INVALID_ENTITY_ID
                query(id) <| $ (enemy_actor: Actor)
                    if enemy_actor.faction != actor_faction
                        found_id = id
                return found_id != INVALID_ENTITY_ID
    return false

[decs(stage = thinking)]
def think(eid: EntityId; var actor: Actor; var behavior: Behavior; var movement: Movement)
    
    if behavior.state == BehaviorState Fighting && actor.attacked_entity_id != INVALID_ENTITY_ID
        return

    let current_cell_coordinates = world_position_cell_coordinates(map, actor.position)
    var attackable_enemy_id : EntityId
    if try_find_attackable_enemy(eid, actor.faction, current_cell_coordinates, attackable_enemy_id)
        behavior.state = BehaviorState Fighting
        actor.attacked_entity_id = attackable_enemy_id

    behavior.state = BehaviorState Walking
    let path_length = length(map.cells[behavior.start_cell_index].path_to_keep)
    if behavior.path_step + 1 < path_length - 1
        if current_cell_coordinates == world_position_cell_coordinates(map, movement.target_position)
            ++behavior.path_step
            var next_target_cell = map.cells[behavior.start_cell_index].path_to_keep[path_length - behavior.path_step - 1]
            movement.target_position = cell_world_center(map, next_target_cell)