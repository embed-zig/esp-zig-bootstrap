// Covers the core small-bool-vector lowering path from patch 090.

var sink: u32 = 0;

fn pack(v: @Vector(4, bool)) u32 {
    return @as(u32, @intFromBool(v[0])) |
        (@as(u32, @intFromBool(v[1])) << 1) |
        (@as(u32, @intFromBool(v[2])) << 2) |
        (@as(u32, @intFromBool(v[3])) << 3);
}

noinline fn observe(v: @Vector(4, bool)) void {
    @atomicStore(u32, &sink, pack(v), .seq_cst);
}

export fn repro(seed: u32) u32 {
    const lhs: @Vector(4, bool) = .{
        (seed & 0x1) != 0,
        (seed & 0x2) != 0,
        (seed & 0x4) != 0,
        (seed & 0x8) != 0,
    };
    const rhs: @Vector(4, bool) = .{
        ((seed + 1) & 0x1) != 0,
        ((seed + 1) & 0x2) != 0,
        ((seed + 1) & 0x4) != 0,
        ((seed + 1) & 0x8) != 0,
    };
    const extra: @Vector(4, bool) = .{
        ((seed + 2) & 0x1) != 0,
        ((seed + 2) & 0x2) != 0,
        ((seed + 2) & 0x4) != 0,
        ((seed + 2) & 0x8) != 0,
    };

    const out = (lhs | rhs) | extra;
    observe(out);
    return pack(out);
}
