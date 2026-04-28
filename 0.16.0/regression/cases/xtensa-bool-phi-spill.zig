// Covers the Debug multi-block small-bool spill/reload path. Returning a
// phi-selected v2/v4 bool vector used to route BR2/BR4 through the wrong
// AE_VALIGN spill pseudos instead of the byte stack-slot path.

fn pack2(v: @Vector(2, bool)) u32 {
    const bits: u2 = @bitCast(v);
    return @as(u32, bits);
}

fn pack4(v: @Vector(4, bool)) u32 {
    const bits: u4 = @bitCast(v);
    return @as(u32, bits);
}

noinline fn spill_phi_ret_v2(cond: bool) @Vector(2, bool) {
    const yes: @Vector(2, bool) = .{ true, false };
    const no: @Vector(2, bool) = .{ false, true };
    return if (cond) yes else no;
}

noinline fn spill_phi_ret_v4(cond: bool) @Vector(4, bool) {
    const yes: @Vector(4, bool) = .{ true, false, true, false };
    const no: @Vector(4, bool) = .{ false, true, false, true };
    return if (cond) yes else no;
}

export fn repro(seed: u32) u32 {
    const out2 = pack2(spill_phi_ret_v2((seed & 1) != 0));
    const out4 = pack4(spill_phi_ret_v4((seed & 2) != 0)) << 8;
    return out2 | out4;
}
