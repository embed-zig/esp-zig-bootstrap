// Covers scalar bool returns that optimize to an inverted i1 compare. The
// Xtensa DAG can form a promoted i32 XOR with a still-illegal narrow operand
// unless integer operand promotion handles bitwise nodes.

noinline fn flag(value: u16) bool {
    return (value & 1) == 0;
}

export fn repro(value: u16) u32 {
    return if (flag(value)) 1 else 0;
}
