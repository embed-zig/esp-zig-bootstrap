// Covers float-compare-driven scalar selects of small bool vectors. Optimized
// builds used to bypass the small-bool mask lowering and emit SELECT_CC_FP with
// a v2/v3/v4 bool result, which Xtensa could not select.

fn pack2(v: @Vector(2, bool)) u32 {
    return @as(u32, @intFromBool(v[0])) |
        (@as(u32, @intFromBool(v[1])) << 1);
}

fn pack3(v: @Vector(3, bool)) u32 {
    return @as(u32, @intFromBool(v[0])) |
        (@as(u32, @intFromBool(v[1])) << 1) |
        (@as(u32, @intFromBool(v[2])) << 2);
}

fn pack4(v: @Vector(4, bool)) u32 {
    return @as(u32, @intFromBool(v[0])) |
        (@as(u32, @intFromBool(v[1])) << 1) |
        (@as(u32, @intFromBool(v[2])) << 2) |
        (@as(u32, @intFromBool(v[3])) << 3);
}

noinline fn choose2(seed: u32) @Vector(2, bool) {
    const x: f32 = @floatFromInt(seed & 31);
    const y: f32 = @floatFromInt((seed >> 1) & 31);
    const a: @Vector(2, bool) = .{ true, false };
    const b: @Vector(2, bool) = .{ false, true };
    return if (x < y) a else b;
}

noinline fn choose3(seed: u32) @Vector(3, bool) {
    const x: f32 = @floatFromInt(seed & 15);
    const y: f32 = @floatFromInt((seed ^ 7) & 15);
    const a: @Vector(3, bool) = .{ true, false, true };
    const b: @Vector(3, bool) = .{ false, true, false };
    return if (x == y) a else b;
}

noinline fn choose4(seed: u32) @Vector(4, bool) {
    const x: f32 = @floatFromInt(seed & 63);
    const y: f32 = @floatFromInt((seed + 3) & 63);
    const cond = x < y;
    const a: @Vector(4, bool) = .{ true, false, true, false };
    const b: @Vector(4, bool) = .{ false, true, false, true };
    return if (cond) a else b;
}

export fn repro(seed: u32) u32 {
    const out2 = pack2(choose2(seed));
    const out3 = pack3(choose3(seed)) << 4;
    const out4 = pack4(choose4(seed)) << 8;
    return out2 | out3 | out4;
}
