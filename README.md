# FreeBSD lsblk

A work-in-progress lsblk utility for FreeBSD aimed to be as Linux-compatible as possible.

The command line arguments are not implemented yet. Currently just runs as is.

At the moment the RM (Removable) column isn't implementable unless someone can give me advice or contribute a change for it.

Maj/Min *will not* be supported since FreeBSD has already abstracted away the need for those old-school Unix numbers.

Example of output:
```
% ./zig-out/bin/flsblk
NAME                         SIZE RO TYPE MOUNTPOINTS
nda0                        1863G  0 disk
├─nda0p1                     260M  0 part
├─nda0p2                     512K  0 part
└─nda0p3                    1862G  0 part
nda1                        1863G  0 disk
├─nda1p1                     260M  0 part
├─nda1p2                     512K  0 part
└─nda1p3                    1862G  0 part
da0                          231G  0 disk
├─da0s1                       32M  0 part /media/EFISYS
├─da0s2                     1364M  0 part
└─da0s2a                    1364M  0 part /media/FreeBSD_Install
zroot/vm/devices/archlinux   100G  0 zvol
├─archlinuxp1               1024M  0 part
└─archlinuxp2                 98G  0 part
zroot/vm/devices/win11       300G  0 zvol
├─win11p1                    100M  0 part
├─win11p2                     16M  0 part
├─win11p3                    299G  0 part
└─win11p4                    649M  0 part
```

Written in Zig as a preference language since:
* It's relatively easy to integrate with FreeBSD's base libraries without bindings.
* I'm using it as a learning tool for the base libraries.
