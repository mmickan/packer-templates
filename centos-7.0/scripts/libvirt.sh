# fix networking configuration for gold master:
# - don't tie the configured ethernet interface to a specific MAC address
# - ensure IPv6 settings are present and correct
sed -i'' \
    -e '/^IPV6INIT=/d' \
    -e '/^IPV6_AUTOCONF=/d' \
    -e '/^IPV6_DEFAULTGW=/d' \
    -e '/^IPV6ADDR=/d' \
    -e '/^HWADDR=/d' /etc/sysconfig/network-scripts/ifcfg-eth0
cat >>/etc/sysconfig/network-scripts/ifcfg-eth0 <<EOF
IPV6INIT=yes
IPV6_AUTOCONF=yes
EOF
