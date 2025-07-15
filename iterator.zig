const std = @import("std");
const mem = std.mem;
const print = std.debug.print;

const freebsd = @import("cimports.zig").freebsd;

pub fn GClass(comptime input: type, comptime output: type) type {
    return struct {
        const Self = @This();

        node: ?*output,

        pub fn init(node: *const input) Self {
            return .{
                .node = @ptrCast(@field(node, geomField()).lh_first),
            };
        }

        pub fn next(self: *Self) ?*output {
            const node = self.node orelse return null;
            self.node = @field(node, geomField()).le_next;
            return node;
        }

        fn geomField() []const u8 {
            const outputType = @typeName(output);
            const types = [_][]const u8{
                "cimport.struct_gclass",
                "cimport.struct_ggeom",
                "cimport.struct_gprovider",
            };
            const fields = [_][]const u8{
                "lg_class",
                "lg_geom",
                "lg_provider",
            };
            for (types, fields) |_type, field|
                if (mem.eql(u8, outputType, _type))
                    return field;
            @compileError(
                \\iterator.GClass's output type needs to be either of the following:
                \\  freebsd.gclass
                \\  freebsd.ggeom
                \\  freebsd.gprovider
            );
        }
    };
}

pub fn GeomQuery(comptime query: []const u8) type {
    return struct {
        const Self = @This();

        gtree: GClass(freebsd.gmesh, freebsd.gclass),

        pub fn init(mesh: *const freebsd.gmesh) Self {
            return .{
                .gtree = GClass(freebsd.gmesh, freebsd.gclass).init(mesh),
            };
        }

        pub fn next(self: *Self) ?*freebsd.gclass {
            while (self.gtree.next()) |gclass| {
                const lg_name = mem.span(gclass.lg_name);
                if (mem.eql(u8, lg_name, query))
                    return gclass;
            }
            return null;
        }
    };
}

pub const ProviderName = struct {
    const Self = @This();

    geoms: ?GClass(freebsd.gclass, freebsd.ggeom),
    providers: ?GClass(freebsd.ggeom, freebsd.gprovider),

    pub fn init(mesh: *const freebsd.gmesh, comptime query: []const u8) Self {
        var queryIter = GeomQuery(query).init(mesh);
        return .{
            .geoms = if (queryIter.next()) |gclass| GClass(freebsd.gclass, freebsd.ggeom).init(gclass) else null,
            .providers = null,
        };
    }

    pub fn next(self: *Self) ?[]const u8 {
        if (self.providers) |*providers| {
            if (providers.*.next()) |provider| {
                return mem.span(provider.lg_name);
            }
        }
        if (self.geoms) |*geoms| {
            if (geoms.*.next()) |geom| {
                self.providers = GClass(freebsd.ggeom, freebsd.gprovider).init(geom);
                if (self.providers.?.next()) |provider| {
                    return mem.span(provider.lg_name);
                }
            }
        }
        return null;
    }
};
