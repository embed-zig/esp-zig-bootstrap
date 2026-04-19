// Indirectly covers the v4 boolean register path touched by patch 110 while
// staying close to the already validated bool-vector regression shape.

var sink: u32 = 0;

fn pack(v: @Vector(4, bool)) u32 {
    return @as(u32, @intFromBool(v[0])) |
        (@as(u32, @intFromBool(v[1])) << 1) |
        (@as(u32, @intFromBool(v[2])) << 2) |
        (@as(u32, @intFromBool(v[3])) << 3);
}

noinline fn touch(values: *[8]@Vector(4, bool)) void {
    const merged = values[3] | values[4];
    @atomicStore(u32, &sink, pack(merged), .seq_cst);
}

export fn repro(seed: u32) u32 {
    var values: [8]@Vector(4, bool) = undefined;
    values[0] = .{ ((seed + 0) & 1) != 0, ((seed + 0) & 2) != 0, ((seed + 0) & 4) != 0, ((seed + 0) & 8) != 0 };
    values[1] = .{ ((seed + 1) & 1) != 0, ((seed + 1) & 2) != 0, ((seed + 1) & 4) != 0, ((seed + 1) & 8) != 0 };
    values[2] = .{ ((seed + 2) & 1) != 0, ((seed + 2) & 2) != 0, ((seed + 2) & 4) != 0, ((seed + 2) & 8) != 0 };
    values[3] = .{ ((seed + 3) & 1) != 0, ((seed + 3) & 2) != 0, ((seed + 3) & 4) != 0, ((seed + 3) & 8) != 0 };
    values[4] = .{ ((seed + 4) & 1) != 0, ((seed + 4) & 2) != 0, ((seed + 4) & 4) != 0, ((seed + 4) & 8) != 0 };
    values[5] = .{ ((seed + 5) & 1) != 0, ((seed + 5) & 2) != 0, ((seed + 5) & 4) != 0, ((seed + 5) & 8) != 0 };
    values[6] = .{ ((seed + 6) & 1) != 0, ((seed + 6) & 2) != 0, ((seed + 6) & 4) != 0, ((seed + 6) & 8) != 0 };
    values[7] = .{ ((seed + 7) & 1) != 0, ((seed + 7) & 2) != 0, ((seed + 7) & 4) != 0, ((seed + 7) & 8) != 0 };

    touch(&values);
    const out = (values[0] | values[1]) | (values[6] | values[7]);
    const bits = pack(out);
    @atomicStore(u32, &sink, bits, .seq_cst);
    return bits;
}
