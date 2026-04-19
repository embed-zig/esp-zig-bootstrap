// Defensive coverage for the v2i1 path. The main regressions focused on v4i1,
// but the same lowering family also handles v2i1.

var sink: u32 = 0;

fn pack(v: @Vector(2, bool)) u32 {
    return @as(u32, @intFromBool(v[0])) |
        (@as(u32, @intFromBool(v[1])) << 1);
}

export fn repro(seed: u32) u32 {
    var values: [6]@Vector(2, bool) = undefined;
    values[0] = .{ ((seed + 0) & 1) != 0, ((seed + 0) & 2) != 0 };
    values[1] = .{ ((seed + 1) & 1) != 0, ((seed + 1) & 2) != 0 };
    values[2] = .{ false, false };
    values[3] = .{ ((seed + 3) & 1) != 0, ((seed + 3) & 2) != 0 };
    values[4] = .{ false, false };
    values[5] = .{ false, false };

    values[2][0] = values[0][1];
    values[2][1] = values[1][0];
    values[4] = values[2] | values[3];
    values[5][0] = values[4][1];
    values[5][1] = values[0][0];

    const bits = pack(values[4]) | (pack(values[5]) << 2);
    @atomicStore(u32, &sink, bits, .seq_cst);
    return bits;
}
