// Covers a Debug-only v2 bool-vector path where the condition is also reused as
// a selected value while the other arm is a shuffle-derived bool vector. Xtensa
// used to reach `Impossible reg-to-reg copy` when BR2 physreg copies were
// inserted after small-bool lowering.

fn mask2(v: @Vector(2, bool)) u32 {
    const bits: u2 = @bitCast(v);
    return @as(u32, bits);
}

export fn repro(seed: u32) u32 {
    const cond: @Vector(2, bool) = @bitCast(@as(u2, @truncate(seed ^ 0x3)));
    const shuffled = @shuffle(
        bool,
        cond,
        @as(@Vector(2, bool), .{ !cond[0], !cond[1] }),
        @as(@Vector(2, i32), .{ 1, -1 }),
    );
    return mask2(@select(bool, cond, shuffled, cond));
}
