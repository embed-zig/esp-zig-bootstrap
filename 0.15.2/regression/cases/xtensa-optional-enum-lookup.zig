// Reproduces Xtensa misdecode of an optional enum returned by a lookup helper.
// The shape is intentionally neutral: a state object holds two optional slots,
// the caller snapshots both slots, then decodes the `?Tag` returned by lookup.

const Tag = enum {
    first,
    second,
};

const Slot = struct {
    tag: Tag,
    key: u16,
    bytes: [6]u8,
    kind: u8,
    value_a: u16,
    value_b: u16,
    value_c: u16,
};

const Table = struct {
    state: u8 = 0,
    queue: [288]u8 = [_]u8{0} ** 288,
    id: [6]u8 = .{0} ** 6,
    id_known: bool = false,
    flag_a: bool = false,
    flag_b: bool = false,
    flag_c: bool = false,
    first_slot: ?Slot = null,
    second_slot: ?Slot = null,
    last_status: u8 = 0,

    fn getSlot(self: *const Table, tag: Tag) ?Slot {
        return switch (tag) {
            .first => self.first_slot,
            .second => self.second_slot,
        };
    }

    fn lookupTag(self: *const Table, key: u16) ?Tag {
        if (self.first_slot) |slot| {
            if (slot.key == key) return .first;
        }
        if (self.second_slot) |slot| {
            if (slot.key == key) return .second;
        }
        return null;
    }
};

const State = struct {
    context: usize = 0,
    config: [48]u8 = [_]u8{0} ** 48,
    table: Table = .{},
    first_buffer: [1056]u8 = [_]u8{0} ** 1056,
    second_buffer: [1056]u8 = [_]u8{0} ** 1056,
    lock: usize = 0,
    signal: usize = 0,
    running: bool = false,
    initialized: bool = false,
    worker: ?usize = null,
    active_tags: u8 = 0,
    pending_error: ?u8 = null,
    dispatching_second: bool = false,

    fn resolveTag(self: *const State, key: u16) ?Tag {
        const first_slot = self.table.getSlot(.first);
        const second_slot = self.table.getSlot(.second);
        const tag = self.table.lookupTag(key);

        const tag_name = if (tag) |resolved_tag| @tagName(resolved_tag) else "none";
        observe(
            tag_name.ptr,
            tag_name.len,
            first_slot != null,
            if (first_slot) |slot| slot.key else 0,
            second_slot != null,
            if (second_slot) |slot| slot.key else 0,
        );

        return tag;
    }
};

extern fn observe(
    tag_name: [*]const u8,
    tag_name_len: usize,
    first_present: bool,
    first_key: u16,
    second_present: bool,
    second_key: u16,
) void;

export fn repro(state: *const State, key: u16) u32 {
    const first_slot = state.table.getSlot(.first);
    const second_slot = state.table.getSlot(.second);
    const tag = state.resolveTag(key);

    return encode(tag, first_slot, second_slot);
}

fn encode(tag: ?Tag, first_slot: ?Slot, second_slot: ?Slot) u32 {
    const tag_code: u32 = if (tag) |resolved_tag|
        switch (resolved_tag) {
            .first => 1,
            .second => 2,
        }
    else
        0;
    const first_present: u32 = if (first_slot != null) 1 else 0;
    const second_present: u32 = if (second_slot != null) 1 else 0;
    const first_key: u32 = if (first_slot) |slot| slot.key else 0;
    const second_key: u32 = if (second_slot) |slot| slot.key else 0;

    return tag_code |
        (first_present << 8) |
        (second_present << 9) |
        (first_key << 16) |
        (second_key << 24);
}
