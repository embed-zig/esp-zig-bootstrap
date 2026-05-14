// Covers scalar bool arguments to internal helpers. Debug lowering can leave an
// i1 value feeding a fastcc call argument, so the Xtensa backend must promote it
// before type legalization.

noinline fn consume(ptr: *u32, enabled: bool, value: u16) void {
    if (enabled) {
        ptr.* = @as(u32, value);
    }
}

export fn repro(ptr: *u32, value: u16) void {
    consume(ptr, (value & 1) != 0, 0);
}
