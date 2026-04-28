// Covers the Debug-only v2 bool shuffle path when one input is produced by a
// scalar if-expression before SelectionDAG lowers the shuffle.

fn pack2(v: @Vector(2, bool)) u32 {
    return @as(u32, @intFromBool(v[0])) |
        (@as(u32, @intFromBool(v[1])) << 1);
}

export fn repro(seed: u32) u32 {
    const first = if (((seed >> 6) & 1) != 0)
        @as(@Vector(2, bool), .{ true, true })
    else
        @as(@Vector(2, bool), .{ false, false });
    const second: @Vector(2, bool) = .{ false, false };
    const out = @shuffle(bool, first, second, @as(@Vector(2, i32), .{ 0, -1 }));
    return pack2(out);
}
