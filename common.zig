const std = @import("std");
const mem = std.mem;

const print = std.debug.print;

pub const Flags = struct {
    const Self = @This();

    bytes: bool,

    pub fn init() Self {
        return .{
            .bytes = false,
        };
    }

    pub fn parse(self: *Self) void {
        var args = std.process.args();
        _ = args.skip();
        while (args.next()) |arg| {
            if (arg[0] == '-' and arg[1] != '-') {
                self.shortOptions(arg[1..]);
            }
            else if (arg[0] == '-' and arg[1] == '-') {
                self.longOptions(arg[2..]);
            }
        }
    }

    fn shortOptions(self: *Self, flags: []const u8) void {
        for (flags) |flag| {
            switch (flag) {
                'b' => self.bytes = true,
                else => continue,
            }
        }
    }

    fn longOptions(self: *Self, flag: []const u8) void {
        if (mem.eql(u8, flag, "bytes")) {
            self.bytes = true;
        }
    }
};
