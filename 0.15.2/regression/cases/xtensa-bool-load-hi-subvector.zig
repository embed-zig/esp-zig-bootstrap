// Covers a Debug path where extracting the high half of a loaded bool vector
// must shift the packed byte before rebuilding the smaller bool vector.

fn pack2(v: @Vector(2, bool)) u32 {
    const bits: u2 = @bitCast(v);
    return @as(u32, bits);
}

export fn repro(ptr: *const @Vector(4, bool)) u32 {
    const loaded = ptr.*;
    const hi = @shuffle(
        bool,
        loaded,
        @as(@Vector(4, bool), .{ false, false, false, false }),
        @as(@Vector(2, i32), .{ 2, 3 }),
    );
    return pack2(hi);
}
