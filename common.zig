const std = @import("std");
const mem = std.mem;

const print = std.debug.print;

pub const Flags = struct {
    const Self = @This();

    allocator: mem.Allocator,
    args: [][:0]u8,
    bytes: bool,

    pub fn init(allocator: mem.Allocator) !Self {
        return .{
            .allocator = allocator,
            .args = try std.process.argsAlloc(allocator),
            .bytes = false,
        };
    }

    pub fn deinit(self: *Self) void {
        std.process.argsFree(self.allocator, self.args);
    }

    pub fn parse(self: *Self) void {
        for (self.args[1..]) |arg| {
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
