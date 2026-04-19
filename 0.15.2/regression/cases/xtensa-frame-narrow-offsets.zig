// Defensive coverage for narrow stack accesses. This stays close to the old
// invalid-offset investigation shape with mixed u8/u16/u32 loads under pressure.

const InitError = error{ InitFailed };

var seed: u32 = 1;
var sink: u32 = 0;

fn next() u32 {
    const x = @atomicLoad(u32, &seed, .seq_cst);
    @atomicStore(u32, &seed, x *% 1664525 +% 1013904223, .seq_cst);
    return x;
}

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

noinline fn observe(x: u32) void {
    @atomicStore(u32, &sink, x, .seq_cst);
}

const BytesBox = struct {
    tag: u16,
    data: [320]u8,
};

const HalfsBox = struct {
    tag: u16,
    data: [224]u16,
};

const WordsBox = struct {
    tag: u16,
    data: [160]u32,
};

noinline fn initBytesBox() InitError!BytesBox {
    const x = next();
    if ((x & 0xfff) == 0x155) return error.InitFailed;
    var out: BytesBox = undefined;
    out.tag = @truncate(x);
    for (&out.data, 0..) |*slot, i| {
        slot.* = @truncate(i ^ x ^ next());
    }
    return out;
}

noinline fn initHalfsBox() InitError!HalfsBox {
    const x = next();
    if ((x & 0xfff) == 0x2aa) return error.InitFailed;
    var out: HalfsBox = undefined;
    out.tag = @truncate(x);
    for (&out.data, 0..) |*slot, i| {
        slot.* = @truncate((i * 3) ^ x ^ next());
    }
    return out;
}

noinline fn initWordsBox() InitError!WordsBox {
    const x = next();
    if ((x & 0xfff) == 0x3cc) return error.InitFailed;
    var out: WordsBox = undefined;
    out.tag = @truncate(x);
    for (&out.data, 0..) |*slot, i| {
        slot.* = i *% 17 +% x +% next();
    }
    return out;
}

export fn repro() void {
    const bytes_box = initBytesBox() catch unreachable;
    errdefer observe(bytes_box.tag);
    const halfs_box = initHalfsBox() catch unreachable;
    errdefer observe(halfs_box.tag);
    const words_box = initWordsBox() catch unreachable;
    errdefer observe(words_box.tag);

    var bytes = bytes_box.data;
    var halfs = halfs_box.data;
    var words = words_box.data;

    const v00: u32 = words[0];
    const v01: u32 = words[20];
    const v02: u32 = words[40];
    const v03: u32 = words[60];
    const v04: u32 = words[80];
    const v05: u32 = words[100];
    const v06: u32 = words[120];
    const v07: u32 = words[140];
    const v08: u32 = words[10];
    const v09: u32 = words[30];
    const v10: u32 = words[50];
    const v11: u32 = words[70];
    const b0: u32 = bytes[319];
    const b1: u32 = bytes[302];
    const b2: u32 = bytes[270];
    const b3: u32 = bytes[236];
    const b4: u32 = bytes[198];
    const b5: u32 = bytes[160];
    const h0: u32 = halfs[223];
    const h1: u32 = halfs[214];
    const h2: u32 = halfs[202];
    const h3: u32 = halfs[186];
    const h4: u32 = halfs[170];
    const h5: u32 = halfs[152];

    pressure(v00, v01, h0, b0);
    pressure(v02, v03, h1, b1);
    pressure(v04, v05, h2, b2);
    pressure(v06, v07, h3, b3);

    words[156] = b0 ^ h0;
    words[157] = b1 ^ h1;
    bytes[311] = @truncate(v00);
    halfs[219] = @truncate(v01);

    observe(
        v00 ^ v01 ^ v02 ^ v03 ^ v04 ^ v05 ^ v06 ^ v07 ^
            b0 ^ b1 ^ b2 ^ b3 ^ b4 ^ b5 ^
            h0 ^ h1 ^ h2 ^ h3 ^ h4 ^ h5 ^
            v08 ^ v09 ^ v10 ^ v11,
    );
}
