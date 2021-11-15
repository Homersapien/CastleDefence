require daslib/media
require daslib/decs_boost
require map
require entities

let GROUND_COLORS = [[uint[]
    0x33BB33;
    0x117711;
    0x22A022;
    0x998877;
    0x3355FF
]]

let BUILDING_COLORS = [[uint[]
    0x000000;
    0x3355FF;
    0x7788BB;
    0x7788BB;
    0x7788BB
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

[decs(stage = draw)]
def draw_actor(var entity: Actor)
    fill_circle(entity.position.x, entity.position.y, entity.size * 0.5, 0xFFFFFF)