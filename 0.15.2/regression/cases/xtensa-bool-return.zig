// Covers v2/v4 bool-vector returns that SelectionDAG scalarizes to i2/i4 masks
// before the Xtensa call ABI rebuilds them at the caller.

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

noinline fn make2(seed: u32) @Vector(2, bool) {
    return .{
        (seed & 1) != 0,
        (seed & 2) != 0,
    };
}

noinline fn make4(seed: u32) @Vector(4, bool) {
    return .{
        (seed & 1) != 0,
        (seed & 2) != 0,
        (seed & 4) != 0,
        (seed & 8) != 0,
    };
}

noinline fn bounce4(a: @Vector(4, bool), b: @Vector(4, bool)) @Vector(4, bool) {
    _ = b;
    return a;
}

export fn repro(seed: u32) u32 {
    const first = pack2(make2(seed));
    const second = pack4(make4(seed ^ 0x5)) << 8;

    const a = make4(seed + 3);
    const b = make4(seed + 9);
    const third = pack4(bounce4(a, b)) << 16;

    return first | second | third;
}
