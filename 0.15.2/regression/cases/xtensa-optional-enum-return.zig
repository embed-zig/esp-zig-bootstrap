// Reproduces Xtensa ReleaseSmall misdecode of an inlined helper returning an
// optional enum. One branch returns .first, but the bad lowering reads the
// two-byte optional value as a halfword and classifies { .first, present } as
// .second.

const Tag = enum { first, second };
const Code = enum(u8) { first = 4, second = 5, group = 6 };

const Input = extern struct {
    code: u8,
    payload: u8,
};

fn codeValue(comptime code: Code) u8 {
    return @intFromEnum(code);
}

fn classify(input: Input, mapped: ?Code) ?Tag {
    switch (input.code) {
        codeValue(.first) => return .first,
        codeValue(.second) => return .second,
        codeValue(.group) => switch (mapped orelse return null) {
            .first => return .first,
            .second => return .second,
            else => return null,
        },
        else => return null,
    }
}

export fn repro(input: Input, mapped_raw: u8) u32 {
    const mapped: ?Code = switch (mapped_raw) {
        codeValue(.first) => .first,
        codeValue(.second) => .second,
        else => null,
    };

    const tag = classify(input, mapped) orelse return 0;
    return switch (tag) {
        .first => 1,
        .second => 2,
    };
}
