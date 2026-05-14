// Covers exported scalar bool returns. The Xtensa C ABI return path must
// promote i1 to an i32 return register before type legalization.

export fn repro(value: u16) bool {
    return (value & 1) == 0;
}
