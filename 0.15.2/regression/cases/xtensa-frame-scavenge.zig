// Covers the frame-index scavenging fixes from patches 115 and 120.

const InitError = error{ OutOfMemory, InitFailed };

var seed: u32 = 1;
var sink: u32 = 0;

fn next() u32 {
    const x = @atomicLoad(u32, &seed, .seq_cst);
    @atomicStore(u32, &seed, x *% 1664525 +% 1013904223, .seq_cst);
    return x;
}

const Allocator = struct {
    pub fn create(_: Allocator, comptime T: type) InitError!*T {
        return @ptrFromInt(0x2000 + @as(usize, next() & 0xff) * 32);
    }

    pub fn destroy(_: Allocator, _: anytype) void {}
};

const InitConfig = struct {
    allocator: Allocator,
};

fn Blob(comptime n: usize) type {
    return struct {
        bytes: [n]u8 = [_]u8{0} ** n,
    };
}

const ChunkA = Blob(384);
const ChunkB = Blob(448);
const ChunkC = Blob(512);
const ChunkD = Blob(576);
const ChunkE = Blob(640);
const ChunkF = Blob(704);

fn fill(comptime T: type, salt: u32) T {
    var out: T = .{};
    inline for (0..@sizeOf(T)) |i| {
        @as(*[@sizeOf(T)]u8, @ptrCast(&out)).*[i] = @truncate((salt >> @intCast(i % 16)) +% i);
    }
    return out;
}

noinline fn initA() ChunkA {
    return fill(ChunkA, next());
}

noinline fn initB() ChunkB {
    return fill(ChunkB, next());
}

noinline fn initC() InitError!ChunkC {
    const x = next();
    if ((x & 0x10000) == 0x3141) return error.InitFailed;
    return fill(ChunkC, x);
}

noinline fn initD(_: ChunkA, _: ChunkB) InitError!ChunkD {
    const x = next();
    if ((x & 0x20000) == 0x2718) return error.InitFailed;
    return fill(ChunkD, x);
}

noinline fn initE(_: ChunkC) InitError!ChunkE {
    const x = next();
    if ((x & 0x40000) == 0x1111) return error.InitFailed;
    return fill(ChunkE, x);
}

noinline fn initF(_: ChunkD, _: ChunkE) InitError!ChunkF {
    const x = next();
    if ((x & 0x80000) == 0x2222) return error.InitFailed;
    return fill(ChunkF, x);
}

noinline fn observe(x: u32) void {
    @atomicStore(u32, &sink, x, .seq_cst);
}

const Runtime = struct {
    allocator: Allocator,
    a: ChunkA,
    b: ChunkB,
    c: ChunkC,
    d: ChunkD,
    e: ChunkE,
    f: ChunkF,

    pub fn init(cfg: InitConfig) InitError!*Runtime {
        const runtime = try cfg.allocator.create(Runtime);
        errdefer cfg.allocator.destroy(runtime);

        runtime.allocator = cfg.allocator;
        runtime.a = initA();
        runtime.b = initB();

        const c = try initC();
        runtime.c = c;
        errdefer cfg.allocator.destroy(runtime);

        const d = try initD(runtime.a, runtime.b);
        runtime.d = d;
        errdefer {
            const tmp = c;
            observe(tmp.bytes[0]);
            cfg.allocator.destroy(runtime);
        }

        const e = try initE(c);
        runtime.e = e;
        errdefer {
            const tmp_d = d;
            const tmp_e = e;
            observe(tmp_d.bytes[1] +% tmp_e.bytes[2]);
            cfg.allocator.destroy(runtime);
        }

        const f = try initF(d, e);
        runtime.f = f;

        var scratch0: ChunkF = f;
        var scratch1: ChunkE = e;
        var scratch2: ChunkD = d;
        var scratch3: ChunkC = c;
        var scratch4: ChunkB = runtime.b;
        var scratch5: ChunkA = runtime.a;

        const mask =
            @as(u32, scratch0.bytes[0]) ^
            (@as(u32, scratch1.bytes[17]) << 1) ^
            (@as(u32, scratch2.bytes[33]) << 2) ^
            (@as(u32, scratch3.bytes[49]) << 3) ^
            (@as(u32, scratch4.bytes[65]) << 4) ^
            (@as(u32, scratch5.bytes[81]) << 5);
        observe(mask);
        observe(@as(u32, scratch0.bytes[7]) + scratch1.bytes[9] + scratch2.bytes[11]);

        scratch0 = fill(ChunkF, mask);
        scratch1 = fill(ChunkE, mask + 1);
        scratch2 = fill(ChunkD, mask + 2);
        scratch3 = fill(ChunkC, mask + 3);
        scratch4 = fill(ChunkB, mask + 4);
        scratch5 = fill(ChunkA, mask + 5);

        observe(
            @as(u32, scratch0.bytes[13]) ^
                (@as(u32, scratch1.bytes[21]) << 1) ^
                (@as(u32, scratch2.bytes[34]) << 2) ^
                (@as(u32, scratch3.bytes[55]) << 3) ^
                (@as(u32, scratch4.bytes[89]) << 4) ^
                (@as(u32, scratch5.bytes[144]) << 5),
        );

        return runtime;
    }
};

export fn repro() void {
    _ = Runtime.init(.{ .allocator = .{} }) catch unreachable;
}
