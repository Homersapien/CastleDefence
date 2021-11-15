require math
require misc
require daslib/decs_boost

let
    KEEP_POSITION_NORMALIZED_PADDING = 0.3
    ENVIRONMENT_PADDING = 2
    KEEP_MARGIN = 4
    KEEP_PASSAGEWAY_WIDTH = 2
    ROCKS_AMOUNT = 0.3
    FOREST_AMOUNT = 0.3

var map : Map

enum GroundType
    Grass
    Forest
    FelledForest
    Rock
    Castle

[export]
struct Cell
    ground_type: GroundType = GroundType Grass
    path_to_keep: array<int2>
    entitity_ids: array<EntityId>

[export]
struct Map
    width: int = 0
    height: int = 0
    cell_size: float = 1.0
    cells: array<Cell>
    keep_coordinates: int2
    paths: array<array<int2>>

def initialize_map(var map: Map; width: int; height: int; cell_size: float)
    map.width = width
    map.height = height
    map.cell_size = cell_size
    resize(map.cells, width * height)

def map_world_size(map: Map)
    return float2(float(map.width) * map.cell_size, float(map.height) * map.cell_size)

def cell_index(map: Map; x, y: int)
    return map.width * y + x

def cell_index(map: Map; coordinate: int2)
    return coordinate.x + map.width * coordinate.y

def cell_coordinate_is_valid(map: Map; coordinate: int2) : bool
    return coordinate.x >= 0 && coordinate.y >= 0 && coordinate.x < map.width && coordinate.y < map.height

def cell_coordinates(map: Map; index: int) : int2
    return int2(index % map.width, index / map.width)

def cell_world_origin(map: Map; coordinates: int2) : float2
    return float2(coordinates.x, coordinates.y) * map.cell_size

def cell_world_center(map: Map; coordinates: int2) : float2
    return float2(coordinates.x, coordinates.y) * map.cell_size + float2(0.5 * map.cell_size)

def world_position_cell_coordinates(map: Map; world_position: float2) : int2
    return map.cell_size != 0.0 ? int2(floori(world_position.x / map.cell_size), floori(world_position.y / map.cell_size)) : int2(0, 0)

def reset_cell(var cell: Cell)
    cell.ground_type = GroundType Grass

def place_keep(var map: Map)
    let padding = floori(float(min(map.width, map.height)) * KEEP_POSITION_NORMALIZED_PADDING)
    map.keep_coordinates = int2(
        random_int_in_range(padding, map.width - padding),
        random_int_in_range(padding, map.height - padding))
    var cell_index = cell_index(map, map.keep_coordinates)
    map.cells[cell_index].ground_type = GroundType Castle
    
def place_environment(var map: Map)
    place_random_ground_of_type(map, GroundType Rock, ROCKS_AMOUNT, ENVIRONMENT_PADDING)
    place_random_ground_of_type(map, GroundType Forest, FOREST_AMOUNT, ENVIRONMENT_PADDING)
    return

def place_random_ground_of_type(var map: Map; ground_type: GroundType; amount: float; padding: int)
    
    let keep_coordinates = map.keep_coordinates

    for x in range(padding, map.width - padding)
        for y in range(padding, map.height - padding)
            if abs(x - keep_coordinates.x) > KEEP_MARGIN || abs(y - keep_coordinates.y) > KEEP_MARGIN
                let index = cell_index(map, x, y)
                if (map.cells[index].ground_type == GroundType Grass && random_float() < amount)
                    map.cells[index].ground_type = ground_type

    fill_holes_in_ground_cells(map, ground_type, padding)
    fill_holes_in_ground_cells(map, ground_type, padding)
    clear_tiny_ground_cells(map, ground_type, padding)
    clear_tiny_ground_cells(map, ground_type, padding)

    let center_coordinates = int2(map.width, map.height) / 2
    var passageway_direction = nonzero_sign(center_coordinates - keep_coordinates)
    clear_passageway(map, keep_coordinates, int2(passageway_direction.x, 0), ground_type)
    clear_passageway(map, keep_coordinates, int2(0, passageway_direction.y), ground_type)

def clear_passageway(var map: Map; start; direction: int2; ground_type: GroundType)
    assert(direction != int2(0, 0))
    var coordinate = start
    let side = int2(direction.y, direction.x)
    while cell_coordinate_is_valid(map, coordinate)
        var side_offset = -side * KEEP_PASSAGEWAY_WIDTH / 2
        for _ in range(KEEP_PASSAGEWAY_WIDTH)
            let index = cell_index(map, coordinate + side_offset)
            if map.cells[index].ground_type == ground_type
                map.cells[index].ground_type = GroundType Grass
            side_offset += side
        coordinate += direction

def fill_holes_in_ground_cells(var map: Map; ground_type: GroundType; padding: int)
    for x in range(padding, map.width - padding)
        for y in range(padding, map.height - padding)
            let index = cell_index(map, x, y)
            var adjacent_cells = 0
            increment_if_ground_matches(adjacent_cells, map, x + 1, y, ground_type)
            increment_if_ground_matches(adjacent_cells, map, x, y + 1, ground_type)
            increment_if_ground_matches(adjacent_cells, map, x - 1, y, ground_type)
            increment_if_ground_matches(adjacent_cells, map, x, y - 1, ground_type)
            if adjacent_cells >= 3
                map.cells[index].ground_type = ground_type
            else
                increment_if_ground_matches(adjacent_cells, map, x + 1, y + 1, ground_type)
                increment_if_ground_matches(adjacent_cells, map, x - 1, y + 1, ground_type)
                increment_if_ground_matches(adjacent_cells, map, x + 1, y - 1, ground_type)
                increment_if_ground_matches(adjacent_cells, map, x - 1, y - 1, ground_type)
                if adjacent_cells >= 5
                    map.cells[index].ground_type = ground_type

def clear_tiny_ground_cells(var map: Map; ground_type: GroundType; padding: int)
    for x in range(padding, map.width - padding)
        for y in range(padding, map.height - padding)
            let index = cell_index(map, x, y)
            if map.cells[index].ground_type == ground_type
                var adjacent_cells_x = 0
                increment_if_ground_matches(adjacent_cells_x, map, x + 1, y, ground_type)
                increment_if_ground_matches(adjacent_cells_x, map, x - 1, y, ground_type)
                var adjacent_cells_y = 0
                increment_if_ground_matches(adjacent_cells_y, map, x, y + 1, ground_type)
                increment_if_ground_matches(adjacent_cells_y, map, x, y - 1, ground_type)
                var diagonal_cells = 0
                increment_if_ground_matches(diagonal_cells, map, x + 1, y + 1, ground_type)
                increment_if_ground_matches(diagonal_cells, map, x - 1, y + 1, ground_type)
                increment_if_ground_matches(diagonal_cells, map, x + 1, y - 1, ground_type)
                increment_if_ground_matches(diagonal_cells, map, x - 1, y - 1, ground_type)
                
                let cellIsPartOfGroup = (adjacent_cells_x > 0 || adjacent_cells_y > 0) && (adjacent_cells_x + adjacent_cells_y + diagonal_cells) >= 3

                if (!cellIsPartOfGroup)
                    map.cells[index].ground_type = GroundType Grass

def increment_if_ground_matches(var counter: int&; map: Map; x, y: int; ground_type: GroundType)
    if (map.cells[cell_index(map, x, y)].ground_type == ground_type)
        counter += 1

[export]
def generate_map(var map: Map)
    for cell in map.cells
        reset_cell(cell)
    place_keep(map)
    place_environment(map)
    return

def find_path_to_keep_once(var map: Map; start: int2)
    if length(map.cells[cell_index(map, start)].path_to_keep) == 0
        map.cells[cell_index(map, start)].path_to_keep <- find_path(map, start, map.keep_coordinates)

enum PathfindingCellState
    Undiscovered
    Open
    Closed

struct PathfindingCell
    cost_so_far: float = FLT_MAX
    heuristic: float = FLT_MAX
    parent_index: int = -1
    state: PathfindingCellState

def estinamed_cost(cell: PathfindingCell) : float
    return cell.cost_so_far + cell.heuristic

def cell_is_passable(map: Map; coordinates: int2) : bool
    let ground_type = map.cells[cell_index(map, coordinates)].ground_type
    return ground_type != GroundType Rock && ground_type != GroundType Forest

def find_path(map: Map; start, end: int2) : array<int2>
    
    var cells: array<PathfindingCell>
    resize(cells, map.width * map.height)
    var open_cells: array<int2>
    push(open_cells, start)
    let start_cell_index = cell_index(map, start)
    cells[start_cell_index].cost_so_far = 0.0
    cells[start_cell_index].heuristic = length(float2(end - start))
    cells[start_cell_index].state = PathfindingCellState Open
    cells[start_cell_index].parent_index = -1
    
    while length(open_cells) > 0
        
        // Pop the best open cell (supposed to be a sorted list)
        var best_index = 0
        var best_estimated_cost = estinamed_cost(cells[cell_index(map, open_cells[0])])
        for index in range (1, length(open_cells) - 1)
            var estimated_cost = estinamed_cost(cells[cell_index(map, open_cells[index])])
            if estimated_cost < best_estimated_cost
                best_index = index
                best_estimated_cost = estimated_cost
                
        var cell = open_cells[best_index]
        erase(open_cells, best_index)
        let cell_index = cell_index(map, cell)
        cells[cell_index].state = PathfindingCellState Closed

        if cell == end
            var path: array<int2>
            var index = cell_index(map, cell)
            while (cells[index].parent_index != -1)
                push(path, cell_coordinates(map, index))
                index = cells[index].parent_index
            return <- path

        let adjacent_cells = [[int2[4]
            cell + int2(0, 1);
            cell + int2(1, 0);
            cell + int2(0, -1);
            cell + int2(-1, 0)]]
        
        let cost_so_far = cells[cell_index].cost_so_far + 1.0
        for adjacent_cell in adjacent_cells
            if cell_coordinate_is_valid(map, adjacent_cell) && cell_is_passable(map, adjacent_cell)
                let adjacent_index = cell_index(map, adjacent_cell)
                if cells[adjacent_index].state == PathfindingCellState Undiscovered || cost_so_far < cells[adjacent_index].cost_so_far
                    cells[adjacent_index].cost_so_far = cost_so_far
                    cells[adjacent_index].parent_index = cell_index
                    if cells[adjacent_index].state != PathfindingCellState Open
                        cells[adjacent_index].heuristic = length(float2(end - adjacent_cell))
                        push(open_cells, adjacent_cell)
                    cells[adjacent_index].state = PathfindingCellState Open

    var path: array<int2>
    push(path, end)
    push(path, start)
    return <- path
        
def random_border_cell_coordinates(map: Map)
    var index = random_int_in_range(0, map.width * 2 + (map.height - 2) * 2)
    if index < map.width
        return int2(index, 0)
    index -= map.width
    if index < map.width
        return int2(index, map.height - 1)
    index -= map.width
    if index < map.height - 2
        return int2(0, index + 1)
    index -= map.height - 2
    return int2(map.width - 1, index + 1)

def cell_is_occupied(coordinates: int2)
    return false
