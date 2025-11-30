const std = @import("std");
const fmt = std.fmt;
const mem = std.mem;
const print = std.debug.print;

const freebsd = @import("cimports.zig").freebsd;

const common = @import("common.zig");
const device = @import("device.zig");
const Column = @import("column.zig").Column;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    const allocator = gpa.allocator();

    var mesh: freebsd.gmesh = .{};
    _ = freebsd.geom_gettree(&mesh);

    var data = try device.Data.init(allocator, &mesh);
    defer data.deinit();

    var args = try common.Args.init(allocator);
    defer args.deinit();

    const column = try Column.init(allocator, &data, &args);

    var names, const namesWidth = try column.name();
    defer names.deinit(allocator);

    var sizes, const sizesWidth = try column.size();
    defer sizes.deinit(allocator);

    var readonly, const roWidth = try column.readonly();
    defer readonly.deinit(allocator);

    var types, const typesWidth = try column.type_();
    defer types.deinit(allocator);

    var mountpoints, const mountpointsWidth = try column.mountpoints();
    defer mountpoints.deinit(allocator);

    for (
        names.items,
        sizes.items,
        readonly.items,
        types.items,
        mountpoints.items,
    ) |name, size, ro, type_, mountpoint| {
        print("{s:<[1]} ", .{ name, namesWidth });
        print("{s:>[1]} ", .{ size, sizesWidth + 1 });
        print("{s:>[1]} ", .{ ro, roWidth });
        print("{s:<[1]} ", .{ type_, typesWidth });
        print("{s:<[1]} ", .{ mountpoint, mountpointsWidth });
        print("\n", .{});
    }
}
