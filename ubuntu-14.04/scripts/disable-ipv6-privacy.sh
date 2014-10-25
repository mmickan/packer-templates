sed -i -E 's|^(net.ipv6.conf.[a-z]+.use_tempaddr[ \t]*=[ \t]*)[0-2][ \t]*$|\10|g' /etc/sysctl.d/10-ipv6-privacy.conf
