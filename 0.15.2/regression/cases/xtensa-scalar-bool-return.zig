// Covers scalar bool returns from internal helpers. This lowers to an i1
// fastcc return fed by an i16 compare, which the Xtensa ABI must promote to
// an i32 return register.

noinline fn flag(value: u16) bool {
    return (value & 1) != 0;
}

export fn repro(value: u16) u32 {
    return if (flag(value)) 1 else 0;
}
