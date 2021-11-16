require math
require daslib/media
require daslib/decs_boost
require misc
require map
require actor
require battle

let
    INITIAL_PLAYER_GOLD = 1000
    FARM_HEALTH = 20.0
    FARM_COST = 50
    FARM_GOLD_INCOME = 1
    FARM_GOLD_INCOME_PERIOD = 2.0
    WALL_HEALTH = 200.0
    WALL_COST = 50
    ARCHER_TOWER_HEALTH = 100.0
    ARCHER_TOWER_COST = 250
    ARCHER_TOWER_RANGE = 4.0
    ARCHER_TOWER_RATE = 1.5
    ARCHER_TOWER_DAMAGE = 35.0

var player_gold: int

[decs_template]
struct GoldIncome
    period: float
    amount: int
    time_to_next_income: float

[decs(stage = updating)]
def fight_melee(var income: GoldIncome)
    income.time_to_next_income -= get_delta_time()
    if (income.time_to_next_income <= 0.0)
        income.time_to_next_income += income.period
        player_gold += income.amount

enum BuildingType
    Keep
    Farm
    Wall
    ArcherTower

[decs_template]
struct Building
    appearance: BuildingType

[export]
def reset_building
    player_gold = INITIAL_PLAYER_GOLD

def try_to_build(cell: int2; cost: int) : bool
    if !cell_is_occupied(cell)
        let ground_type = map.cells[cell_index(map, cell)].ground_type
        if ground_type == GroundType Grass || ground_type == GroundType FelledForest
            return try_consume_gold(cost)
    return false

def try_consume_gold(amount: int) : bool
    if player_gold >= amount
        player_gold -= amount
        return true
    return false

def build_farm(cell: int2)
    if try_to_build(cell, FARM_COST)

        let position = cell_world_center(map, cell)

        var entity_id = create_entity <| @ (eid, cmp)
            apply_decs_template(cmp, [[Actor
                position = position,
                size = map.cell_size,
                faction = Faction Defenders
            ]])
            apply_decs_template(cmp, [[Building
                appearance = BuildingType Farm
            ]])
            apply_decs_template(cmp, [[Health
                value = FARM_HEALTH,
                max_value = FARM_HEALTH
            ]])
            apply_decs_template(cmp, [[GoldIncome
                period = FARM_GOLD_INCOME_PERIOD,
                amount = FARM_GOLD_INCOME,
                time_to_next_income = FARM_GOLD_INCOME_PERIOD
            ]])

        on_entity_entered_cell(entity_id, position)

def build_wall(cell: int2)
    if try_to_build(cell, WALL_COST)

        let position = cell_world_center(map, cell)

        var entity_id = create_entity <| @ (eid, cmp)
            apply_decs_template(cmp, [[Actor
                position = position,
                size = map.cell_size,
                faction = Faction Defenders
            ]])
            apply_decs_template(cmp, [[Building
                appearance = BuildingType Wall
            ]])
            apply_decs_template(cmp, [[Health
                value = WALL_HEALTH,
                max_value = WALL_HEALTH
            ]])

        on_entity_entered_cell(entity_id, position)

def build_archer_tower(cell: int2)
    if try_to_build(cell, ARCHER_TOWER_COST)

        let position = cell_world_center(map, cell)

        var entity_id = create_entity <| @ (eid, cmp)
            apply_decs_template(cmp, [[Actor
                position = position,
                size = map.cell_size,
                faction = Faction Defenders
            ]])
            apply_decs_template(cmp, [[Building
                appearance = BuildingType ArcherTower
            ]])
            apply_decs_template(cmp, [[Health
                value = ARCHER_TOWER_HEALTH,
                max_value = ARCHER_TOWER_HEALTH
            ]])
            apply_decs_template(cmp, [[RangedWeapon
                attack_range = ARCHER_TOWER_RANGE,
                damage = ARCHER_TOWER_DAMAGE,
                rate = ARCHER_TOWER_RATE,
                attack_period = rate_to_period(ARCHER_TOWER_RATE)
            ]])

        on_entity_entered_cell(entity_id, position)

[export]
def deconstruct_building(cell: int2)
    return