pub const freebsd = @cImport({
    @cInclude("sys/fcntl.h");
    @cInclude("sys/stat.h");
    @cInclude("sys/disk.h");
    @cInclude("sys/param.h");
    @cInclude("sys/mount.h");
    @cInclude("sys/ucred.h");
    @cInclude("stdio.h");
    @cInclude("stdlib.h");
    @cInclude("mntopts.h");
    @cInclude("libgeom.h");
});
