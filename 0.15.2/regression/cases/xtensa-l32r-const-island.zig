// Covers Debug-only Xtensa L32R constant-island placement for a large function
// with mixed u8/u16/u32 stack accesses under forced AR pressure. Before patch
// 125 this shape could reach assembly with `l32r fixup value out of range`.

noinline fn pressure(a: u32, b: u32, c: u32, d: u32) void {
    asm volatile ("" ::
        [i0] "r" (a),
        [i1] "r" (b),
        [i2] "r" (c),
        [i3] "r" (d)
        : .{
            .a8 = true,
            .a9 = true,
            .a10 = true,
            .a11 = true,
            .a12 = true,
            .a13 = true,
            .a14 = true,
            .a15 = true,
        });
}

export fn repro(seed: u32) u32 {
    @setEvalBranchQuota(5000);

    var bytes: [1280]u8 = [_]u8{0} ** 1280;
    var halfs: [640]u16 = [_]u16{0} ** 640;
    var words: [320]u32 = [_]u32{0} ** 320;
    var acc: u32 = seed;

    inline for (0..1188) |i| {
        const mask: u32 = @as(u32, 1) << @as(u5, @intCast(i % 20));
        if ((seed & mask) != 0) {
            pressure(acc, words[319], halfs[639], bytes[1279]);
            acc +%= words[319] ^ halfs[639] ^ bytes[1279];
            bytes[1263] = @truncate(acc >> @as(u5, @intCast(i % 8)));
            halfs[629] = @truncate(acc >> @as(u5, @intCast(i % 12)));
            words[307] +%= acc ^ @as(u32, i + 1);
        } else {
            pressure(words[307], acc, halfs[629], bytes[1263]);
            acc ^= words[307] +% halfs[629] +% bytes[1263];
            bytes[1279] = @truncate(acc >> @as(u5, @intCast((i + 1) % 8)));
            halfs[639] = @truncate(acc >> @as(u5, @intCast((i + 3) % 12)));
            words[319] = acc +% @as(u32, i + 3);
        }
    }

    return acc;
}
