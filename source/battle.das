require math
require daslib/media
require daslib/decs_boost
require misc
require map
require actor
require movement
require game_result

[decs_template(prefix = "health_")]
struct Health
    value: float
    max_value: float

[decs_template]
struct MeleeWeapon
    attack_range: float
    damage: float
    rate: float
    attack_period: float
    time_since_last_attack: float
    attack_direction: float2

[decs(stage = fighting)]
def fight_melee(eid: EntityId; var actor: Actor; var weapon: MeleeWeapon)

    if actor.attacked_entity_id != INVALID_ENTITY_ID

        // Do an attack if the time has come
        weapon.time_since_last_attack += get_delta_time()
        if weapon.time_since_last_attack >= weapon.attack_period

            weapon.time_since_last_attack -= weapon.attack_period

            // Save the attack direction
            let target_found = query(actor.attacked_entity_id) <| $ (attacked_actor: Actor)
                weapon.attack_direction = normalize(attacked_actor.position - actor.position)

            // Deal damage
            update_entity(actor.attacked_entity_id) <| @ (eidd, cmp)
                
                var health = 0.0
                health = get(cmp, "health_value", health) // wat?
                set(cmp, "health_value", max(health - weapon.damage, 0.0))
                
                if health <= 0.0
                    kill_actor(actor.attacked_entity_id)
            
            // Reset the target
            if !target_found
                actor.attacked_entity_id = INVALID_ENTITY_ID

def kill_actor(entity_id: EntityId)
    query(entity_id) <| $ (var attacked_actor: Actor; movement: Movement)
        on_entity_left_cell(entity_id, movement.cell_index)
    delete_entity(entity_id)
    on_actor_killed(entity_id)

def on_actor_killed(entity_id: EntityId)
    if entity_id == keep_id
        on_defeat()