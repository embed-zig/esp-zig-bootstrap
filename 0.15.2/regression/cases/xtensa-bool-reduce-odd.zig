// Covers Debug-only @reduce(.And/.Or/.Xor) on odd-width bool vectors after
// legalization introduces extract_subvector on truncated bool masks.

var slot7: @Vector(7, bool) = @splat(false);

fn reduceBits(v: anytype) u32 {
    const all = @reduce(.And, v);
    const any = @reduce(.Or, v);
    const parity = @reduce(.Xor, v);

    return @as(u32, @intFromBool(all)) |
        (@as(u32, @intFromBool(any)) << 1) |
        (@as(u32, @intFromBool(parity)) << 2);
}

export fn repro(seed: u32) u32 {
    const v3: @Vector(3, bool) = .{
        (seed & 1) != 0,
        (seed & 2) != 0,
        (seed & 4) != 0,
    };
    const v5: @Vector(5, bool) = .{
        (seed & 1) != 0,
        (seed & 2) != 0,
        (seed & 4) != 0,
        (seed & 8) != 0,
        (seed & 16) != 0,
    };

    slot7 = .{
        (seed & 1) != 0,
        (seed & 2) != 0,
        (seed & 4) != 0,
        (seed & 8) != 0,
        (seed & 16) != 0,
        (seed & 32) != 0,
        (seed & 64) != 0,
    };

    const out3 = reduceBits(v3);
    const out5 = reduceBits(v5) << 4;
    const out7 = reduceBits(slot7) << 8;
    return out3 | out5 | out7;
}
