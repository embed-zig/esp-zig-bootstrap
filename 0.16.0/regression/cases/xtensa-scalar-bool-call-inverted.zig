// Covers scalar bool arguments produced by explicit negation. This exercises
// the call argument promotion path after bool inversion.

noinline fn consume(ptr: *u32, enabled: bool, value: u16) void {
    if (enabled) {
        ptr.* = @as(u32, value);
    }
}

export fn repro(ptr: *u32, value: u16) void {
    consume(ptr, !((value & 1) != 0), value);
}
