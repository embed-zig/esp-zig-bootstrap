// Covers vector float compares that produce bool vectors. Xtensa's SETCC
// custom lowering used to assume scalar results and crashed when a vector
// compare fed pack/reduce/extract/select users.

fn pack2(v: @Vector(2, bool)) u32 {
    return @as(u32, @intFromBool(v[0])) |
        (@as(u32, @intFromBool(v[1])) << 1);
}

fn pack3(v: @Vector(3, bool)) u32 {
    return @as(u32, @intFromBool(v[0])) |
        (@as(u32, @intFromBool(v[1])) << 1) |
        (@as(u32, @intFromBool(v[2])) << 2);
}

fn vec3(seed: u32, shift: u5) @Vector(3, f32) {
    return .{
        @floatFromInt((seed >> shift) & 31),
        @floatFromInt((seed >> (shift + 1)) & 31),
        @floatFromInt((seed >> (shift + 2)) & 31),
    };
}

export fn repro(seed: u32) u32 {
    const lhs2: @Vector(2, f32) = .{
        @floatFromInt((seed >> 0) & 31),
        @floatFromInt((seed >> 1) & 31),
    };
    const rhs2: @Vector(2, f32) = .{
        @floatFromInt((seed >> 3) & 31),
        @floatFromInt((seed >> 4) & 31),
    };
    const out2 = pack2(lhs2 < rhs2);

    const lhs3 = vec3(seed, 0);
    const rhs3 = vec3(seed, 3);
    const cmp3 = lhs3 < rhs3;
    const out3 = pack3(@select(bool, cmp3, @as(@Vector(3, bool), .{ true, false, true }), @as(@Vector(3, bool), .{ false, true, false }))) << 4;

    const reduced = @as(u32, @intFromBool(@reduce(.Or, cmp3))) << 8;
    const extracted = @as(u32, @intFromBool(cmp3[@as(u2, @truncate(seed >> 6)) % 3])) << 12;

    return out2 | out3 | reduced | extracted;
}
