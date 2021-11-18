require dasbox
require daslib/random
require math

var seed: int4

[export]
def initialize_random
    randomize_seed(seed)
    return

[export]
def random_int_in_range(min_inclusive; max_exclusive) : int
    return (random_int(seed) % (max_exclusive - min_inclusive)) + min_inclusive

[export]
def random_float_in_range(min, max : float) : float
    return random_float(seed) * (max - min) + min

[export]
def random_float
    return random_float(seed)

[export]
def nonzero_sign(vector: int2) : int2
    let s = sign(vector)
    return int2(s.x != 0 ? s.x : 1, s.y != 0 ? s.y : 1)
    
[export]
def remap(value, min1, max1, min2, max2: float)
    return clamp((value - min1) / (max1 - min1) * (max2 - min2) + min2, min2, max2)

[export]
def remap01(value, min1, max1: float)
    return saturate((value - min1) / (max1 - min1))

[export]
def move_to(from, to: float2; delta_time: float; speed: float)
    let vector = to - from
    let distance = length(vector)
    if distance > 0.0
        let delta_distance = speed * delta_time
        return from + (vector / distance) * min(delta_distance, distance)
    else
        return to

def erase(var vector; item)
    let index = find_index(vector, item)
    if index >= 0
        erase(vector, index)