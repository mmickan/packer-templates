cat >/etc/init/ttyS0.conf <<EOF
# ttyS0 - getty
#
# This service maintains a getty on ttyS0 from the point the system is
# started until it is shut down again.

start on (stopped rc RUNLEVEL=[2345] and stopped cloud-final)
stop on runlevel [!2345]

respawn
exec /sbin/getty -L 115200 ttyS0 xterm
EOF

sed -i -E 's|^(GRUB_CMDLINE_LINUX_DEFAULT=)"(.*)"|\1"\2 console=ttyS0"|' /etc/default/grub
update-grub
