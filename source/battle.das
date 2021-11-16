require math
require daslib/media
require daslib/decs_boost
require misc
require map
require actor
require movement
require game_result

let PROJECTILE_HIT_DISTANCE_THRESHOLD = 0.1
let PROJECTILE_SPEED = 3.0

[decs_template(prefix = "health_")]
struct Health
    value: float
    max_value: float

[decs_template]
struct MeleeWeapon
    damage: float
    rate: float
    attack_period: float
    time_since_last_attack: float
    attack_direction: float2

[decs_template]
struct RangedWeapon
    attack_range: float
    damage: float
    rate: float
    attack_period: float
    time_since_last_attack: float

[decs_template]
struct Projectile
    position: float2
    speed: float
    damage: float
    target_id: EntityId

[export]
def rate_to_period(rate: float) : float
    return rate > 0.0 ? 1.0 / rate : FLT_MAX

def deal_damage(hit_entity_id: EntityId; amount: float)
   
    update_entity(hit_entity_id) <| @ (eidd, cmp) 
            
        var health = 0.0
        health = get(cmp, "health_value", health) // wat?
        health = max(health - amount , 0.0)
        set(cmp, "health_value", health)
        
        if health <= 0.0
            kill_actor(hit_entity_id)

[decs(stage = fighting)]
def fight_melee(eid: EntityId; var actor: Actor; var weapon: MeleeWeapon)
    
    weapon.time_since_last_attack += get_delta_time()

    if actor.attacked_entity_id != INVALID_ENTITY_ID

        // Do an attack if the time has come
        if weapon.time_since_last_attack >= weapon.attack_period

            weapon.time_since_last_attack -= weapon.attack_period

            // Save the attack direction
            let target_found = query(actor.attacked_entity_id) <| $ (attacked_actor: Actor)
                weapon.attack_direction = normalize(attacked_actor.position - actor.position)

            // Deal the damage
            deal_damage(actor.attacked_entity_id, weapon.damage)
            
            // Reset the target
            if !target_found
                actor.attacked_entity_id = INVALID_ENTITY_ID
    else 
        weapon.time_since_last_attack = min(weapon.time_since_last_attack, weapon.attack_period)

[decs(stage = fighting)]
def fight_ranged(eid: EntityId; var actor: Actor; var weapon: RangedWeapon)

    weapon.time_since_last_attack += get_delta_time()

    if actor.attacked_entity_id != INVALID_ENTITY_ID

        // Do an attack if the time has come
        if weapon.time_since_last_attack >= weapon.attack_period

            weapon.time_since_last_attack -= weapon.attack_period

            // Spawn a projectile
            create_entity <| @ ( eid, cmp )
                cmp |> set ("eid", eid)
                apply_decs_template(cmp, [[Projectile
                    position = actor.position,
                    speed = PROJECTILE_SPEED,
                    damage = weapon.damage,
                    target_id = actor.attacked_entity_id
                ]])
    else 
        weapon.time_since_last_attack = min(weapon.time_since_last_attack, weapon.attack_period)

[decs(stage = fighting)]
def update_projectile(eid: EntityId; var projectile: Projectile)

    let target_found = query(projectile.target_id) <| $ (target_actor: Actor)
        
        // Move the projectile
        projectile.position = move_to(
            projectile.position,
            target_actor.position,
            get_delta_time(),
            projectile.speed)
        
        // If the target is close enough, deal the damage
        if (length(projectile.position - target_actor.position) < PROJECTILE_HIT_DISTANCE_THRESHOLD)
            deal_damage(projectile.target_id, projectile.damage)
            delete_entity(eid)

    if !target_found
        delete_entity(eid)

def try_find_attackable_enemy(actor_id: EntityId; actor_faction: Faction; actor_position: float2; var found_id: EntityId) : bool
    let actor_cell = world_position_cell_coordinates(map, actor_position)
    
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

def try_find_attackable_enemy_in_range(actor_id: EntityId; actor_faction: Faction; actor_position: float2; search_range: float; var found_id: EntityId) : bool
    let actor_cell = world_position_cell_coordinates(map, actor_position)
    let square_size = ceili(search_range * 2.0 / map.cell_size)
    let square_origin = actor_cell - int2(square_size / 2)
    var nearest_distance = FLT_MAX
    var nearest_entity_id = INVALID_ENTITY_ID
    var current_entity_id: EntityId
    for x in range(0, square_size)
        for y in range(0, square_size)
            if try_find_attackable_enemy_in_single_cell(actor_id, actor_faction, square_origin + int2(x, y), current_entity_id)
                query(current_entity_id) <| $ (enemy_actor: Actor)
                    let distance = length(actor_position - enemy_actor.position)
                    if distance <= search_range && distance < nearest_distance
                        nearest_distance = distance
                        nearest_entity_id = current_entity_id
    found_id = nearest_entity_id
    return nearest_entity_id != INVALID_ENTITY_ID

def kill_actor(entity_id: EntityId)
    let movement_found = query(entity_id) <| $ (movement: Movement)
        on_entity_left_cell(entity_id, movement.cell_index)
    if !movement_found
        query(entity_id) <| $ (var actor: Actor)
            let actor_cell = world_position_cell_coordinates(map, actor.position)
            on_entity_left_cell(entity_id, cell_index(map, actor_cell))
    delete_entity(entity_id)
    on_actor_killed(entity_id)

def on_actor_killed(entity_id: EntityId)
    if entity_id == keep_id
        on_defeat()