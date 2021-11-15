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
