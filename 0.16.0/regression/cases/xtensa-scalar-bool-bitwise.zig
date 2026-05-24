// Covers scalar bool bitwise promotion in Debug. This keeps i1 AND/OR/XOR
// values live across an internal fastcc bool return, matching the shape that
// used to crash in r4 and later exposed a SelectionDAG combine loop.

noinline fn mix(seed: u16) bool {
    return (((seed & 1) != 0) & ((seed & 2) != 0)) |
        (((seed & 4) != 0) ^ true);
}

export fn repro(seed: u16) u32 {
    return @intFromBool(mix(seed));
}
