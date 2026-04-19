// Covers scalar-condition selects of small bool vectors. Optimized builds can
// form either SELECT_CC or plain SELECT depending on whether the condition is a
// comparison or an already-materialized bool value.

fn pack1(v: @Vector(1, bool)) u32 {
    return @as(u32, @intFromBool(v[0]));
}

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

noinline fn choose1(flag: bool) @Vector(1, bool) {
    const yes: @Vector(1, bool) = .{ true };
    const no: @Vector(1, bool) = .{ false };
    return if (flag) yes else no;
}

noinline fn choose2(seed: u32) @Vector(2, bool) {
    const a: @Vector(2, bool) = .{ true, false };
    const b: @Vector(2, bool) = .{ false, true };
    return if ((seed & 1) != 0) a else b;
}

noinline fn choose4(seed: u32) @Vector(4, bool) {
    const a: @Vector(4, bool) = .{ true, false, true, false };
    const b: @Vector(4, bool) = .{ false, true, false, true };
    return if ((seed & 3) == 2) a else b;
}

export fn repro(seed: u32) u32 {
    const out1 = pack1(choose1((seed & 1) != 0));
    const out2 = pack2(choose2(seed)) << 4;
    const out4 = pack4(choose4(seed)) << 8;
    return out1 | out2 | out4;
}
