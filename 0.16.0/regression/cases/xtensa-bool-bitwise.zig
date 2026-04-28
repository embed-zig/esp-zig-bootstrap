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
    const lhs2: @Vector(2, bool) = .{ (seed & 1) != 0, (seed & 2) != 0 };
    const rhs2: @Vector(2, bool) = .{ ((seed + 1) & 1) != 0, ((seed + 1) & 2) != 0 };
    const lhs4: @Vector(4, bool) = .{
        (seed & 1) != 0,
        (seed & 2) != 0,
        (seed & 4) != 0,
        (seed & 8) != 0,
    };
    const rhs4: @Vector(4, bool) = .{
        ((seed + 3) & 1) != 0,
        ((seed + 3) & 2) != 0,
        ((seed + 3) & 4) != 0,
        ((seed + 3) & 8) != 0,
    };

    const out2 = lhs2 & rhs2;
    const out4 = lhs4 ^ rhs4;
    return pack2(out2) | (pack4(out4) << 8);
}
