// Covers INSERT_VECTOR_ELT lowering from patch 095.

var sink: u32 = 0;

fn pack(v: @Vector(4, bool)) u32 {
    return @as(u32, @intFromBool(v[0])) |
        (@as(u32, @intFromBool(v[1])) << 1) |
        (@as(u32, @intFromBool(v[2])) << 2) |
        (@as(u32, @intFromBool(v[3])) << 3);
}

export fn repro(seed: u32) u32 {
    var value: @Vector(4, bool) = @as(@Vector(4, bool), @splat(false));

    value[0] = (seed & 0x1) != 0;
    value[1] = (seed & 0x2) != 0;
    value[2] = (seed & 0x4) != 0;
    value[3] = (seed & 0x8) != 0;

    const bits = pack(value);
    @atomicStore(u32, &sink, bits, .seq_cst);
    return bits;
}
