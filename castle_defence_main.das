require daslib/media
require daslib/decs_boost
require source/misc
require source/map
require source/spawning
require source/actor
require source/building
require source/rendering
require source/game_result
require source/input

[export]
def initialize
    set_window_title("Castle Defence")
    initialize_random()
    initialize_map(map, 40, 40, 1.0)
    restart_game()

def restart_game
    restart()
    reset_game_result()
    for id in actors_ids
        delete_entity(id)
    generate_map(map)
    spawn_keep(cell_world_center(map, map.keep_coordinates))
    reset_enemy_spawning()
    initialize_input()
    reset_building()

let THINKING_PERIOD = 0.1
var time_since_last_thinking : float = 0.0

[export]
def act(delta_time: float)
    
    decs_stage("input")

    time_since_last_thinking += delta_time
    if (time_since_last_thinking >= THINKING_PERIOD)
        time_since_last_thinking -= THINKING_PERIOD
        decs_stage("thinking")

    decs_stage("updating")
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
    decs_stage("ui")
    render_ui()
    return
