const std = @import("std");
const mem = std.mem;

const print = std.debug.print;

pub const Args = struct {
    const Self = @This();

    _flags: std.StringArrayHashMap(bool),
    _opts: std.StringArrayHashMap([]const u8),

    pub fn init(allocator: mem.Allocator) !Self {
        var flags = std.StringArrayHashMap(bool).init(allocator);
        var opts = std.StringArrayHashMap([]const u8).init(allocator);
        const flagKeys = [_][:0]const u8{
            "bytes",
        };
        for (flagKeys) |key|
            try flags.put(key, false);
        parse(&flags, &opts);
        return .{
            ._flags = flags,
            ._opts = opts,
        };
    }

    pub fn deinit(self: *Self) void {
        self._flags.deinit();
        self._opts.deinit();
    }

    pub fn getFlag(self: *const Self, flag: []const u8) bool {
        // If the flag not found, it should panic to help find logic bugs.
        // This helper function also prevents code from looking ugly with unwraps.
        return self._flags.get(flag).?;
    }

    fn parse(flags: *std.StringArrayHashMap(bool), opts: *std.StringArrayHashMap([]const u8)) void {
        _ = opts;
        var args = std.process.args();
        _ = args.skip();
        while (args.next()) |arg| {
            if (arg[0] == '-' and arg[1] != '-') {
                for (arg[1..]) |flag| {
                    switch (flag) {
                        'b' => {
                            if (flags.getPtr("bytes")) |bytes|
                                bytes.* = true;
                        },
                        else => continue,
                    }
                }
            }
            else if (arg[0] == '-' and arg[1] == '-') {
                if (mem.eql(u8, arg[2..], "bytes")) {
                    if (flags.getPtr("bytes")) |bytes|
                        bytes.* = true;
                }
            }
        }
    }
};
