// Covers the non-small bool-vector path that used to be over-matched by the
// small bool bitcast combine in Debug builds.

fn pack4(v: @Vector(4, bool)) u32 {
    return @as(u32, @intFromBool(v[0])) |
        (@as(u32, @intFromBool(v[1])) << 1) |
        (@as(u32, @intFromBool(v[2])) << 2) |
        (@as(u32, @intFromBool(v[3])) << 3);
}

export fn repro(seed: u32) u32 {
    const wide: @Vector(8, bool) = @bitCast(@as(u8, @truncate(seed ^ 0x5a)));
    const low = @shuffle(bool, wide, wide, @as(@Vector(4, i32), .{ 0, 1, 2, 3 }));

    return @as(u32, @intFromBool(wide[0])) |
        (@as(u32, @intFromBool(wide[7])) << 1) |
        (pack4(low) << 8);
}
