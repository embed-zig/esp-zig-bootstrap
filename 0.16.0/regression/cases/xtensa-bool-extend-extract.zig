// Covers the extend-after-extract path from patch 099.

var sink: u32 = 0;

noinline fn touch(p: *[8]@Vector(4, bool)) void {
    const v = p[3] | p[4];
    const mask = @as(u32, @intFromBool(v[0])) |
        (@as(u32, @intFromBool(v[1])) << 1) |
        (@as(u32, @intFromBool(v[2])) << 2) |
        (@as(u32, @intFromBool(v[3])) << 3);
    @atomicStore(u32, &sink, mask, .seq_cst);
}

export fn repro(seed: u32) u32 {
    var arr: [8]@Vector(4, bool) = undefined;
    arr[0] = .{ ((seed + 0) & 1) != 0, ((seed + 0) & 2) != 0, ((seed + 0) & 4) != 0, ((seed + 0) & 8) != 0 };
    arr[1] = .{ ((seed + 1) & 1) != 0, ((seed + 1) & 2) != 0, ((seed + 1) & 4) != 0, ((seed + 1) & 8) != 0 };
    arr[2] = .{ ((seed + 2) & 1) != 0, ((seed + 2) & 2) != 0, ((seed + 2) & 4) != 0, ((seed + 2) & 8) != 0 };
    arr[3] = .{ ((seed + 3) & 1) != 0, ((seed + 3) & 2) != 0, ((seed + 3) & 4) != 0, ((seed + 3) & 8) != 0 };
    arr[4] = .{ ((seed + 4) & 1) != 0, ((seed + 4) & 2) != 0, ((seed + 4) & 4) != 0, ((seed + 4) & 8) != 0 };
    arr[5] = .{ ((seed + 5) & 1) != 0, ((seed + 5) & 2) != 0, ((seed + 5) & 4) != 0, ((seed + 5) & 8) != 0 };
    arr[6] = .{ ((seed + 6) & 1) != 0, ((seed + 6) & 2) != 0, ((seed + 6) & 4) != 0, ((seed + 6) & 8) != 0 };
    arr[7] = .{ ((seed + 7) & 1) != 0, ((seed + 7) & 2) != 0, ((seed + 7) & 4) != 0, ((seed + 7) & 8) != 0 };

    touch(&arr);

    const m0 = arr[0] | arr[1];
    const m1 = arr[2] | arr[3];
    const m2 = arr[4] | arr[5];
    const m3 = arr[6] | arr[7];
    const out = (m0 | m1) | (m2 | m3);

    return @as(u32, @intFromBool(out[0])) |
        (@as(u32, @intFromBool(out[1])) << 1) |
        (@as(u32, @intFromBool(out[2])) << 2) |
        (@as(u32, @intFromBool(out[3])) << 3);
}
