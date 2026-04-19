fn pack4(v: @Vector(4, bool)) u32 {
    return @as(u32, @intFromBool(v[0])) |
        (@as(u32, @intFromBool(v[1])) << 1) |
        (@as(u32, @intFromBool(v[2])) << 2) |
        (@as(u32, @intFromBool(v[3])) << 3);
}

export fn repro(seed: u32) u32 {
    const cond: @Vector(4, bool) = .{
        (seed & 1) != 0,
        (seed & 2) != 0,
        (seed & 4) != 0,
        (seed & 8) != 0,
    };
    const when_true: @Vector(4, bool) = .{ true, false, true, false };
    const when_false: @Vector(4, bool) = .{ false, true, false, true };
    return pack4(@select(bool, cond, when_true, when_false));
}
