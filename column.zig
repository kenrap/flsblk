const std = @import("std");
const fmt = std.fmt;
const mem = std.mem;
const print = std.debug.print;

const freebsd = @import("cimports.zig").freebsd;

const common = @import("common.zig");
const device = @import("device.zig");

fn longestWidth(items: [][]const u8) usize {
    var result: usize = 0;
    for (items) |item| {
        const deviceLen = item.len;
        if (deviceLen > result)
            result = deviceLen;
    }
    return result;
}

pub const Column = struct {
    const Self = @This();

    allocator: mem.Allocator,
    data: *const device.Data,
    maps: [2]std.StringArrayHashMap([][]const u8),
    diskTypes: [2][]const u8,
    dirPaths: [2][]const u8,
    args: *const common.Args,

    pub fn init(allocator: mem.Allocator, data: *const device.Data, args: *const common.Args) !Self {
        return .{
            .allocator = allocator,
            .data = data,
            .maps = [_]std.StringArrayHashMap([][]const u8){
                data.disks,
                data.zvols,
            },
            .diskTypes = [_][]const u8{
                "disk",
                "zvol",
            },
            .dirPaths = [_][]const u8{
                "/dev",
                "/dev/zvol",
            },
            .args = args,
        };
    }

    pub fn name(self: *const Self) !struct { std.ArrayList([]const u8), usize } {
        var result = std.ArrayList([]const u8).init(self.allocator);
        try result.append("NAME");
        for (self.maps) |map| {
            var iter = map.iterator();
            while (iter.next()) |entry| {
                const disk = entry.key_ptr.*;
                try result.append(disk);
                const parts: [][]const u8 = entry.value_ptr.*;
                var partNameBegin: usize = 0;
                for (parts[0 .. parts.len - 1]) |part| {
                    partNameBegin = mem.lastIndexOf(u8, part, std.fs.path.basename(disk)) orelse 0;
                    try result.append(try fmt.allocPrint(self.allocator, "├─{s}", .{part[partNameBegin..]}));
                }
                try result.append(try fmt.allocPrint(self.allocator, "└─{s}", .{parts[parts.len - 1][partNameBegin..]}));
            }
        }
        return .{ result, longestWidth(result.items) };
    }

    pub fn type_(self: *const Self) !struct { std.ArrayList([]const u8), usize } {
        var result = std.ArrayList([]const u8).init(self.allocator);
        try result.append("TYPE");
        for (self.maps, self.diskTypes) |map, diskType| {
            var iter = map.iterator();
            while (iter.next()) |entry| {
                try result.append(diskType);
                const parts: [][]const u8 = entry.value_ptr.*;
                for (parts) |_| {
                    try result.append("part");
                }
            }
        }
        return .{ result, longestWidth(result.items) };
    }

    pub fn size(self: *const Self) !struct { std.ArrayList([]const u8), usize } {
        var result = std.ArrayList([]const u8).init(self.allocator);
        try result.append("SIZE");
        for (self.maps, self.dirPaths) |map, dirPath| {
            var iter = map.iterator();
            while (iter.next()) |entry| {
                const disk = entry.key_ptr.*;
                const parts: [][]const u8 = entry.value_ptr.*;
                try result.append(try device.storageSize(self.allocator, try device.mediaSize(try fmt.allocPrint(self.allocator, "{s}/{s}", .{ dirPath, disk })), self.args));
                for (parts) |part| {
                    try result.append(try device.storageSize(self.allocator, try device.mediaSize(try fmt.allocPrint(self.allocator, "{s}/{s}", .{ dirPath, part })), self.args));
                }
            }
        }
        return .{ result, longestWidth(result.items) };
    }

    fn getMountOnName(self: *const Self, mntbufs: []freebsd.struct_statfs, devicePath: []const u8) ![]const u8 {
        for (mntbufs) |mntbuf| {
            const mountFrom = mem.span(@as([*:0]const u8, @ptrCast(mntbuf.f_mntfromname[0..])));
            if (mem.eql(u8, mountFrom, devicePath)) {
                const mountOn = mem.span(@as([*:0]const u8, @ptrCast(mntbuf.f_mntonname[0..])));
                // Needs a duplicate copy to avoid garbled string output
                return try self.allocator.dupe(u8, mountOn);
            }
        }
        return "";
    }

    pub fn mountpoints(self: *const Self) !struct { std.ArrayList([]const u8), usize } {
        var result = std.ArrayList([]const u8).init(self.allocator);
        var mntbuf: [*c]freebsd.struct_statfs = undefined;
        const n: usize = @intCast(freebsd.getmntinfo(&mntbuf, freebsd.MNT_NOWAIT));
        const mntbufs = mntbuf[0..n];
        try result.append("MOUNTPOINTS");
        for (self.maps, self.dirPaths) |map, dirPath| {
            var iter = map.iterator();
            while (iter.next()) |entry| {
                const diskPath = try fmt.allocPrint(self.allocator, "{s}/{s}", .{ dirPath, entry.key_ptr.* });
                try result.append(try self.getMountOnName(mntbufs, diskPath));
                const parts: [][]const u8 = entry.value_ptr.*;
                for (parts) |part| {
                    const partPath = try fmt.allocPrint(self.allocator, "{s}/{s}", .{ dirPath, part });
                    try result.append(try self.getMountOnName(mntbufs, partPath));
                }
            }
        }
        return .{ result, longestWidth(result.items) };
    }

    pub fn readonly(self: *const Self) !struct { std.ArrayList([]const u8), usize } {
        var result = std.ArrayList([]const u8).init(self.allocator);
        try result.append("RO");
        for (self.maps, self.dirPaths) |map, dirPath| {
            var iter = map.iterator();
            while (iter.next()) |entry| {
                const diskPath = try fmt.allocPrint(self.allocator, "{s}/{s}", .{ dirPath, entry.key_ptr.* });
                var mntPoint: ?*freebsd.struct_statfs = freebsd.getmntpoint(@ptrCast(diskPath));
                var ro = "0";
                if (mntPoint) |data| {
                    if (data.*.f_flags & freebsd.MNT_RDONLY == 1) {
                        ro = "1";
                    }
                }
                try result.append(ro);

                const parts: [][]const u8 = entry.value_ptr.*;
                for (parts) |part| {
                    ro = "0";
                    const partPath = try fmt.allocPrint(self.allocator, "{s}/{s}", .{ dirPath, part });
                    mntPoint = freebsd.getmntpoint(@ptrCast(partPath));
                    if (mntPoint) |data| {
                        if (data.*.f_flags & freebsd.MNT_RDONLY == 1) {
                            ro = "1";
                        }
                    }
                    try result.append(ro);
                }
            }
        }
        return .{ result, longestWidth(result.items) };
    }
};
