// Covers the Debug-only vector_shuffle gaps found for small bool vectors.

fn pack2(v: @Vector(2, bool)) u32 {
    return @as(u32, @intFromBool(v[0])) |
        (@as(u32, @intFromBool(v[1])) << 1);
}

fn pack4(v: @Vector(4, bool)) u32 {
    return @as(u32, @intFromBool(v[0])) |
        (@as(u32, @intFromBool(v[1])) << 1) |
        (@as(u32, @intFromBool(v[2])) << 2) |
        (@as(u32, @intFromBool(v[3])) << 3);
}

export fn repro(seed: u32) u32 {
    const a2: @Vector(2, bool) = .{ (seed & 1) != 0, (seed & 2) != 0 };
    const b2: @Vector(2, bool) = .{ ((seed + 1) & 1) != 0, ((seed + 1) & 2) != 0 };
    const out2 = @shuffle(bool, a2, b2, @as(@Vector(2, i32), .{ 0, -2 }));

    const a4: @Vector(4, bool) = .{
        (seed & 1) != 0,
        (seed & 2) != 0,
        (seed & 4) != 0,
        (seed & 8) != 0,
    };
    const b4: @Vector(4, bool) = .{
        ((seed + 1) & 1) != 0,
        ((seed + 1) & 2) != 0,
        ((seed + 1) & 4) != 0,
        ((seed + 1) & 8) != 0,
    };
    const out4 = @shuffle(bool, a4, b4, @as(@Vector(4, i32), .{ 0, -2, 2, -4 }));
    const reverse4 = @shuffle(bool, a4, a4, @as(@Vector(4, i32), .{ 3, 2, 1, 0 }));

    return pack2(out2) | (pack4(out4) << 8) | (pack4(reverse4) << 16);
}
