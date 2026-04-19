// Covers EXTRACT_VECTOR_ELT lowering from patch 097 and vector_extract patterns
// from patch 100.

var sink: u32 = 0;

fn bits(v: @Vector(4, bool)) u32 {
    const b0 = v[0];
    const b1 = v[1];
    const b2 = v[2];
    const b3 = v[3];

    return @as(u32, @intFromBool(b0)) |
        (@as(u32, @intFromBool(b1)) << 1) |
        (@as(u32, @intFromBool(b2)) << 2) |
        (@as(u32, @intFromBool(b3)) << 3);
}

export fn repro(seed: u32) u32 {
    const value: @Vector(4, bool) = .{
        (seed & 0x1) != 0,
        (seed & 0x2) != 0,
        (seed & 0x4) != 0,
        (seed & 0x8) != 0,
    };

    const out = bits(value);
    @atomicStore(u32, &sink, out, .seq_cst);
    return out;
}
