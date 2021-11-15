require daslib/media
require daslib/decs_boost
require map
require actor
require battle
require game_result
require input

let
    ATTACK_AMPLITUDE_MULTIPLIER = 1.0
    ATTACK_DURATION = 0.25
    HEALTH_BAR_WIDTH = 0.8
    HEALTH_BAR_HEIGHT = 0.2
    GAME_RESULTS_OVERLAY_COLOR = 0x40000000
    GAME_RESULT_FONT_SIZE = 40
    CURSOR_WIDTH = 0.1
    CURSOR_COLOR = 0xFFDDCC55 

let GROUND_COLORS = [[uint[]
    0x33BB33;
    0x117711;
    0x22A022;
    0x998877;
    0x3355FF
]]

let FACTION_COLORS = [[uint[]
    0x3355FF;
    0xFF5533
]]

let BORDER_COLOR = 0x20000000

[export]
def reset_camera(var map: Map)
    let map_world_size = map_world_size(map)

    let scale = min(
        float(get_screen_width()) / map_world_size.x,
        float(get_screen_height()) / map_world_size.y)

    setup_2d_camera(0.5 * map_world_size, scale)

[export]
def render_map(var map: Map)
    
    reset_camera(map)
    
    let map_world_size = map_world_size(map)
    
    fill_rect(
        0.0,
        0.0,
        map_world_size.x,
        map_world_size.y,
        GROUND_COLORS[0])

    enable_alpha_blend()
    fill_rect(0.0, 0.0, map.cell_size, map_world_size.y, BORDER_COLOR)
    fill_rect(map_world_size.x - map.cell_size, 0.0, map.cell_size, map_world_size.y, BORDER_COLOR)
    fill_rect(map.cell_size, 0.0, map_world_size.x - 2.0 * map.cell_size, map.cell_size, BORDER_COLOR)
    fill_rect(map.cell_size, map_world_size.y - map.cell_size, map_world_size.x - 2.0 * map.cell_size, map.cell_size, BORDER_COLOR)
    disable_alpha_blend()

    for x in range(map.width)
        for y in range(map.height)
            let cell_index = cell_index(map, x, y)
            let origin = cell_world_origin(map, int2(x, y))
            
            if map.cells[cell_index].ground_type != GroundType Grass
                fill_rect(
                    origin.x,
                    origin.y,
                    map.cell_size,
                    map.cell_size,
                    GROUND_COLORS[int(map.cells[cell_index].ground_type)])
[export]
def render_ui
    if game_result == GameResult Defeat
        let map_world_size = map_world_size(map)
        enable_alpha_blend()
        fill_rect(
            0.0,
            0.0,
            map_world_size.x,
            map_world_size.y,
            GAME_RESULTS_OVERLAY_COLOR)
        disable_alpha_blend()

        setup_2d_camera(float2(get_screen_width() / 2, get_screen_height() / 2), 1.0)
        set_font_size(GAME_RESULT_FONT_SIZE)
        let artificial_center_text_offset = int2(-60, -GAME_RESULT_FONT_SIZE / 2)
        text_out(
            get_screen_width() / 2 + artificial_center_text_offset.x,
            get_screen_height() / 2 + artificial_center_text_offset.y,
            "DEFEAT",
            FACTION_COLORS[1])

[decs(stage = draw)]
def draw_actor(actor: Actor; weapon: Weapon)
    
    var attack_offset = float2(0.0)

    if actor.attacked_entity_id != INVALID_ENTITY_ID
        var attack_factor = sin(saturate(weapon.time_since_last_attack / ATTACK_DURATION) * PI)
        attack_offset = attack_factor * weapon.attack_direction * actor.size * ATTACK_AMPLITUDE_MULTIPLIER

    fill_circle(
        actor.position.x + attack_offset.x,
        actor.position.y + attack_offset.y,
        actor.size * 0.5,
        FACTION_COLORS[int(actor.faction)])

[decs(stage = draw)]
def draw_health(actor: Actor; health: Health)
    if health.value < health.max_value
        
        let position = actor.position + float2(-0.5 * HEALTH_BAR_WIDTH, actor.size * 0.5 + HEALTH_BAR_HEIGHT)

        fill_rect(
            position.x,
            position.y,
            HEALTH_BAR_WIDTH,
            HEALTH_BAR_HEIGHT,
            0xFFFFFF)
            
        fill_rect(
            position.x,
            position.y,
            HEALTH_BAR_WIDTH * saturate(health.value / health.max_value),
            HEALTH_BAR_HEIGHT,
            FACTION_COLORS[int(actor.faction)])

[decs(stage = draw)]
def draw_cursor(cursor: PlayerCursor)
    let cursor_origin = cell_world_origin(map, cursor.cell)
    let line_width = CURSOR_WIDTH * map.cell_size
    
    fill_rect(
        cursor_origin.x,
        cursor_origin.y,
        line_width,
        map.cell_size,
        CURSOR_COLOR)

    fill_rect(
        cursor_origin.x,
        cursor_origin.y,
        map.cell_size,
        line_width,
        CURSOR_COLOR)

    fill_rect(
        cursor_origin.x + map.cell_size - line_width,
        cursor_origin.y,
        line_width,
        map.cell_size,
        CURSOR_COLOR)

    fill_rect(
        cursor_origin.x,
        cursor_origin.y + map.cell_size - line_width,
        map.cell_size,
        line_width,
        CURSOR_COLOR)