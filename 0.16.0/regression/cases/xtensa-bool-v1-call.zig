// Covers the v1i1 call ABI path: passing a single-lane bool vector into a
// helper and receiving one back from a helper.

fn pick(v: @Vector(1, bool)) bool {
    return v[0];
}

fn make(seed: u32) @Vector(1, bool) {
    return .{ (seed & 2) != 0 };
}

export fn repro(seed: u32) u32 {
    const a = @as(u32, @intFromBool(pick(.{ (seed & 1) != 0 })));
    const b = @as(u32, @intFromBool(make(seed)[0])) << 1;
    return a | b;
}
