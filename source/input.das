require daslib/media
require daslib/decs_boost
require misc
require map

[decs_template]
struct PlayerCursor
    cell: int2

def initialize_input()
    create_entity <| @ ( eid, cmp )
        apply_decs_template(cmp, [[PlayerCursor
            cell = map.keep_coordinates + int2(0, 1)
        ]])

[decs(stage = input)]
def process_input(var cursor: PlayerCursor)
    var offset = int2(0, 0)
    if get_key_press(VK_UP) || get_key_down(VK_W)
        offset.y -= 1
    if get_key_press(VK_DOWN) || get_key_down(VK_S)
        offset.y += 1
    if get_key_press(VK_LEFT) || get_key_down(VK_A)
        offset.x -= 1
    if get_key_press(VK_RIGHT) || get_key_down(VK_D)
        offset.x += 1
    
    cursor.cell = clamp_cell_coordinates(map, cursor.cell + offset)
