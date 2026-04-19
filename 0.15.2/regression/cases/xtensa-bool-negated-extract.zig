// Defensive case for the extract-then-negate path. This is aimed at the
// SETEQ/XOR branch in patch 099.

var sink: u32 = 0;

fn pack(v: @Vector(4, bool)) u32 {
    return @as(u32, @intFromBool(v[0])) |
        (@as(u32, @intFromBool(v[1])) << 1) |
        (@as(u32, @intFromBool(v[2])) << 2) |
        (@as(u32, @intFromBool(v[3])) << 3);
}

export fn repro(seed: u32) u32 {
    var values: [4]@Vector(4, bool) = undefined;
    values[0] = .{ ((seed + 0) & 1) != 0, ((seed + 0) & 2) != 0, ((seed + 0) & 4) != 0, ((seed + 0) & 8) != 0 };
    values[1] = .{ ((seed + 1) & 1) != 0, ((seed + 1) & 2) != 0, ((seed + 1) & 4) != 0, ((seed + 1) & 8) != 0 };
    values[2] = .{ ((seed + 2) & 1) != 0, ((seed + 2) & 2) != 0, ((seed + 2) & 4) != 0, ((seed + 2) & 8) != 0 };
    values[3] = .{ ((seed + 3) & 1) != 0, ((seed + 3) & 2) != 0, ((seed + 3) & 4) != 0, ((seed + 3) & 8) != 0 };

    const merged = (values[0] | values[1]) | (values[2] | values[3]);
    const lane0 = @as(u32, @intFromBool(!merged[0]));
    const lane1 = @as(u32, @intFromBool(!merged[1]));
    const lane2 = @as(u32, @intFromBool(merged[2]));
    const lane3 = @as(u32, @intFromBool(!merged[3]));
    const bits = lane0 | (lane1 << 1) | (lane2 << 2) | (lane3 << 3);

    @atomicStore(u32, &sink, bits ^ pack(merged), .seq_cst);
    return bits;
}
