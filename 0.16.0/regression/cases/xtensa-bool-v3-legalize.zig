// Covers @Vector(3, bool) legalization by forcing build/select/shuffle,
// vector @select, call/return, and bitcast paths through the Xtensa backend.

fn pack3(v: @Vector(3, bool)) u32 {
    return @as(u32, @intFromBool(v[0])) |
        (@as(u32, @intFromBool(v[1])) << 1) |
        (@as(u32, @intFromBool(v[2])) << 2);
}

noinline fn build(seed: u32) @Vector(3, bool) {
    return .{
        (seed & 1) != 0,
        (seed & 2) != 0,
        (seed & 4) != 0,
    };
}

noinline fn choose(seed: u32) @Vector(3, bool) {
    const yes: @Vector(3, bool) = .{ true, false, true };
    const no: @Vector(3, bool) = .{ false, true, false };
    return if ((seed & 1) != 0) yes else no;
}

noinline fn shuffled(seed: u32) @Vector(3, bool) {
    const first = build(seed);
    const second: @Vector(3, bool) = .{ true, false, true };
    return @shuffle(bool, first, second, @as(@Vector(3, i32), .{ 0, -2, 2 }));
}

noinline fn selected(seed: u32) @Vector(3, bool) {
    return @select(bool, build(seed), choose(seed), shuffled(seed));
}

noinline fn roundtrip(seed: u32) u32 {
    const bits: u3 = @truncate(seed);
    const value: @Vector(3, bool) = @bitCast(bits);
    const back: u3 = @bitCast(value);
    return pack3(value) | (@as(u32, back) << 3);
}

export fn repro(seed: u32) u32 {
    const out_build = pack3(build(seed));
    const out_choose = pack3(choose(seed)) << 4;
    const out_shuffle = pack3(shuffled(seed)) << 8;
    const out_select = pack3(selected(seed)) << 12;
    const out_bitcast = roundtrip(seed) << 16;
    return out_build | out_choose | out_shuffle | out_select | out_bitcast;
}
