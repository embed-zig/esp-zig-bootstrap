// Debug high-group BR4 repro: patch 110 must shift MOVBA4 fixups by 4
// before the same value is extracted back with `extui ..., 4, 4`.

fn pack(v: @Vector(4, bool)) u32 {
    const bits: u4 = @bitCast(v);
    return @as(u32, bits);
}

noinline fn bounce(
    a0: @Vector(4, bool),
    a1: @Vector(4, bool),
    a2: @Vector(4, bool),
    a3: @Vector(4, bool),
    a4: @Vector(4, bool),
    a5: @Vector(4, bool),
) u32 {
    return pack(a0) |
        (pack(a1) << 4) |
        (pack(a2) << 8) |
        (pack(a3) << 12) |
        (pack(a4) << 16) |
        (pack(a5) << 20);
}

export fn repro(seed: u32) u32 {
    const v1: @Vector(4, bool) = @bitCast(@as(u4, @truncate((seed >> 1) ^ 0x3)));
    const t1: @Vector(4, bool) = @shuffle(bool, v1, v1, @as(@Vector(4, i32), .{ 3, 2, 1, 0 }));
    const t2: @Vector(4, bool) = @select(bool, v1, @as(@Vector(4, bool), .{ v1[0], !v1[1], v1[2], v1[0] }), v1);
    const t3: @Vector(4, bool) = @as(@Vector(4, bool), .{ v1[0], !v1[2], !v1[0], !t2[1] });
    const t4: @Vector(4, bool) = @shuffle(bool, t3, v1, @as(@Vector(4, i32), .{ -4, -3, -2, -1 }));
    const t5: @Vector(4, bool) = @as(@Vector(4, bool), .{ !t2[1], v1[3], t1[1], v1[1] });
    const t6: @Vector(4, bool) = @as(@Vector(4, bool), .{ !v1[2], !t4[1], !v1[2], v1[3] });
    const t7: @Vector(4, bool) = @as(@Vector(4, bool), .{ t6[3], !v1[1], !v1[2], !v1[1] });
    const t8: @Vector(4, bool) = @bitCast(@as(u4, @truncate(bounce(v1, t7, v1, v1, t6, t3))));
    const t9: @Vector(4, bool) = @as(@Vector(4, bool), .{ t6[3], !t6[1], v1[2], !v1[0] });

    return bounce(t3, t4, t5, t6, t7, t8) ^ pack(t9);
}
