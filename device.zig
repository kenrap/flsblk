const std = @import("std");
const fmt = std.fmt;
const mem = std.mem;
const print = std.debug.print;

const freebsd = @import("cimports.zig").freebsd;

const common = @import("common.zig");
const iterator = @import("iterator.zig");

pub const Data = struct {
    const Self = @This();
    const DeviceType = enum {
        disk,
        zvol,
    };

    mesh: *const freebsd.gmesh,
    disks: std.StringArrayHashMap([][]const u8),
    zvols: std.StringArrayHashMap([][]const u8),
    sizes: ?std.StringArrayHashMap([][]const u8),
    permis: ?std.StringArrayHashMap([][]const u8),

    pub fn init(allocator: mem.Allocator, mesh: *const freebsd.gmesh) !Self {
        return .{
            .mesh = mesh,
            .disks = try createDeviceMap(allocator, DeviceType.disk, mesh),
            .zvols = try createDeviceMap(allocator, DeviceType.zvol, mesh),
            .sizes = null,
            .permis = null,
        };
    }

    pub fn deinit(self: *Self) void {
        self.disks.deinit();
        self.zvols.deinit();
        if (self.sizes) |*sizes| {
            sizes.*.deinit();
        }
        if (self.permis) |*permis| {
            permis.*.deinit();
        }
    }

    fn createDeviceMap(allocator: mem.Allocator, comptime deviceType: DeviceType, mesh: *const freebsd.gmesh) !std.StringArrayHashMap([][]const u8) {
        var map = std.StringArrayHashMap([][]const u8).init(allocator);
        var providerNames: iterator.ProviderName = undefined;
        providerNames = iterator.ProviderName.init(
            mesh,
            switch (deviceType) {
                DeviceType.disk => "DISK",
                DeviceType.zvol => "ZFS::ZVOL",
            },
        );
        while (providerNames.next()) |_name| {
            var name = _name;
            const parts = try collectPartNames(allocator, mesh, name);
            if (deviceType == DeviceType.zvol) {
                for (parts.items) |*part| {
                    part.* = part.*[5..];
                }
                name = name[5..];
            }
            try map.put(name, parts.items);
        }
        return map;
    }

    fn collectPartNames(allocator: mem.Allocator, mesh: *const freebsd.gmesh, name: []const u8) !std.ArrayList([]const u8) {
        var list = try std.ArrayList([]const u8).initCapacity(allocator, 8);
        var partsIter = iterator.GeomQuery("PART").init(mesh);
        while (partsIter.next()) |gclass| {
            var geoms = iterator.GClass(freebsd.gclass, freebsd.ggeom).init(gclass);
            while (geoms.next()) |geom| {
                var providers = iterator.GClass(freebsd.ggeom, freebsd.gprovider).init(geom);
                while (providers.next()) |provider| {
                    const providerName = mem.span(provider.lg_name);
                    if (name.len <= providerName.len and mem.eql(u8, name, providerName[0..name.len])) {
                        try list.append(allocator, providerName);
                    }
                }
            }
        }
        return list;
    }
};

pub fn mediaSize(devicePath: []const u8) !usize {
    var size: usize = 0;
    const device = try std.fs.cwd().openFile(devicePath, .{});
    const err = freebsd.ioctl(device.handle, freebsd.DIOCGMEDIASIZE, &size);
    if (err != 0) {
        print("{s}: ioctl(DIOCGMEDIASIZE) failed, probably not a disk.", .{devicePath});
    }
    return size; // Measured in bytes
}

fn digits(num: usize) usize {
    var count: usize = 0;
    var n = num;
    while (n > 0) {
        n /= 10;
        count += 1;
    }
    return count;
}

pub fn storageSize(allocator: mem.Allocator, byteSize: usize, args: *const common.Args) ![]const u8 {
    const storageUnits = [_][]const u8{
        "",
        "K",
        "M",
        "G",
        "T",
        "P",
        "E",
        "Z",
        "Y",
        // For now, let's not worry about what comes after Yottabytes
        // until the distant future.
    };
    const unit = if (!args.getFlag("bytes")) digits(byteSize) / 4 else 0;
    return try fmt.allocPrint(allocator, "{}{s}", .{ byteSize / std.math.pow(usize, 1024, unit), storageUnits[unit] });
}
