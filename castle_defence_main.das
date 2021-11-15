require daslib/media
require daslib/decs_boost
require source/misc
require source/map
require source/spawning
require source/actor
require source/rendering
require source/game_result

[export]
def initialize
    set_window_title("Castle Defence")
    set_resolution(900, 700)
    initialize_random()
    initialize_map(map, 40, 40, 1.0)
    restart_game()

def restart_game
    reset_game_result()
    for id in actors_ids
        delete_entity(id)
    generate_map(map)
    spawn_keep(cell_world_center(map, map.keep_coordinates), 0.8, 500.0)
    spawn_wave(7)

let THINKING_PERIOD = 0.2
var time_since_last_thinking : float = 0.0

[export]
def act(delta_time: float)
    
    time_since_last_thinking += delta_time
    if (time_since_last_thinking >= THINKING_PERIOD)
        time_since_last_thinking -= THINKING_PERIOD
        decs_stage("thinking")

    decs_stage("movement")
    decs_stage("fighting")
    
    if get_key(VK_END)
        restart_game()

    if get_key(VK_ESCAPE)
        schedule_quit_game()

[export]
def draw
    render_map(map)
    decs_stage("draw")
    render_ui()
    return
