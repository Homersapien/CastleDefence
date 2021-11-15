require math
require daslib/media
require daslib/decs_boost

enum GameResult
    None
    Victory
    Defeat

var game_result: GameResult

def reset_game_result()
    game_result = GameResult None

def on_victory()
    game_result = GameResult Victory

def on_defeat()
    game_result = GameResult Defeat