const std = @import("std");
const fmt = std.fmt;
const mem = std.mem;
const print = std.debug.print;

const freebsd = @import("cimports.zig").freebsd;

const common = @import("common.zig");
const device = @import("device.zig");
const Column = @import("column.zig").Column;

fn longestWidth(items: [][]const u8) usize {
    var result: usize = 0;
    for (items) |item| {
        const deviceLen = item.len;
        if (deviceLen > result)
            result = deviceLen;
    }
    return result;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var mesh: freebsd.gmesh = .{};
    _ = freebsd.geom_gettree(&mesh);

    var data = try device.Data.init(allocator, &mesh);
    defer data.deinit();

    var flags = common.Flags.init();
    flags.parse();
    const column = try Column.init(allocator, &data, &flags);

    const names = try column.name();
    defer names.deinit();
    const sizes = try column.size();
    defer sizes.deinit();
    const readonly = try column.readonly();
    defer readonly.deinit();
    const types = try column.type_();
    defer types.deinit();
    const mountpoints = try column.mountpoints();
    defer mountpoints.deinit();

    const namesWidth = longestWidth(names.items);
    const sizesWidth = longestWidth(sizes.items);
    const roWidth = longestWidth(readonly.items);
    const typesWidth = longestWidth(types.items);
    const mountpointsWidth = longestWidth(mountpoints.items);
    for (
        names.items,
        sizes.items,
        readonly.items,
        types.items,
        mountpoints.items,
    ) |name, size, ro, type_, mountpoint| {
        print("{s[0]: <[1]} ", .{ name, namesWidth });
        print("{s[0]: >[1]} ", .{ size, sizesWidth + 1 });
        print("{s[0]: >[1]} ", .{ ro, roWidth });
        print("{s[0]: <[1]} ", .{ type_, typesWidth });
        print("{s[0]: <[1]} ", .{ mountpoint, mountpointsWidth });
        print("\n", .{});
    }
}
