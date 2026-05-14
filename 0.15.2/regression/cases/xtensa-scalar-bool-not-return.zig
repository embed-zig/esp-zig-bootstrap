// Covers explicit scalar bool negation. This can form a promoted i32 XOR with
// a still-illegal narrow operand unless bitwise operand promotion handles it.

noinline fn flag(value: u16) bool {
    return !((value & 1) != 0);
}

export fn repro(value: u16) u32 {
    return @intFromBool(flag(value));
}
