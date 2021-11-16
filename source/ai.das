require math
require daslib/media
require daslib/decs_boost
require misc
require map
require actor
require movement
require battle

enum BehaviorState
    Walking
    Fighting

[decs_template]
struct Behavior
    state: BehaviorState
    start_cell_index: int
    path_step: int = 0

[decs(stage = thinking)]
def find_melee_target(eid: EntityId; var actor: Actor; var behavior: Behavior; weapon: MeleeWeapon)
    
    if behavior.state != BehaviorState Fighting || actor.attacked_entity_id == INVALID_ENTITY_ID
    
        var attackable_enemy_id : EntityId
        if try_find_attackable_enemy(eid, actor.faction, actor.position, attackable_enemy_id)
            behavior.state = BehaviorState Fighting
            actor.attacked_entity_id = attackable_enemy_id
            stop_actor(eid)
        else
            actor.attacked_entity_id = INVALID_ENTITY_ID

[decs(stage = thinking)]
def find_ranged_target(eid: EntityId; var actor: Actor; weapon: RangedWeapon)
    var attackable_enemy_id : EntityId
    if try_find_attackable_enemy_in_range(eid, actor.faction, actor.position, weapon.attack_range, attackable_enemy_id)
        actor.attacked_entity_id = attackable_enemy_id
    else
        actor.attacked_entity_id = INVALID_ENTITY_ID

[decs(stage = thinking)]
def move_to_keep(eid: EntityId; var actor: Actor; var behavior: Behavior; var movement: Movement)
    
    if behavior.state != BehaviorState Fighting || actor.attacked_entity_id == INVALID_ENTITY_ID

        var path_to_keep& = map.cells[behavior.start_cell_index].path_to_keep
        let path_length = length(path_to_keep)

        let current_target_cell = path_to_keep[path_length - behavior.path_step - 1]
        movement.target_position = cell_world_center(map, current_target_cell)

        behavior.state = BehaviorState Walking
        if behavior.path_step + 1 < path_length - 1
            let current_cell_coordinates = world_position_cell_coordinates(map, actor.position)
            if current_cell_coordinates == current_target_cell
                ++behavior.path_step
                let next_target_cell = path_to_keep[path_length - behavior.path_step - 1]
                movement.target_position = cell_world_center(map, next_target_cell)