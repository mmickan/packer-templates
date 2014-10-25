apt-get -y install cloud-init

sed -i -E 's|^(GRUB_CMDLINE_LINUX_DEFAULT=)"(.*)"|\1"\2 ds=nocloud-net"|' /etc/default/grub
update-grub

cat >/etc/cloud/cloud.cfg <<'EOF'
# The top level settings are used as module
# and system configuration.

# A set of users which may be applied and/or used by various modules
# when a 'default' entry is found it will reference the 'default_user'
# from the distro configuration specified below
users:
   - default

# If this is set, 'root' will not be able to ssh in and they 
# will get a message to login instead as the above $user (ubuntu)
disable_root: false

# This will cause the set+update hostname module to not operate (if true)
preserve_hostname: false

# Example datasource config
# datasource: 
#    Ec2: 
#      metadata_urls: [ 'blah.com' ]
#      timeout: 5 # (defaults to 50 seconds)
#      max_wait: 10 # (defaults to 120 seconds)

# The modules that run in the 'init' stage
cloud_init_modules:
 - migrator
 - seed_random
 - bootcmd
 - write-files
 - growpart
 - resizefs
 - set_hostname
 - update_hostname
 - update_etc_hosts
 - ca-certs
 - rsyslog
 - users-groups
 - ssh

# The modules that run in the 'config' stage
cloud_config_modules:
# Emit the cloud config ready event
# this can be used by upstart jobs for 'start on cloud-config'.
 - emit_upstart
 - disk_setup
 - mounts
 - ssh-import-id
 - locale
 - set-passwords
 - grub-dpkg
 - apt-pipelining
 - apt-configure
 - package-update-upgrade-install
 - landscape
 - timezone
 - puppet
 - chef
 - salt-minion
 - mcollective
 - disable-ec2-metadata
 - runcmd
 - byobu

# The modules that run in the 'final' stage
cloud_final_modules:
 - rightscale_userdata
 - scripts-vendor
 - scripts-per-once
 - scripts-per-boot
 - scripts-per-instance
 - scripts-user
 - ssh-authkey-fingerprints
 - keys-to-console
 - phone-home
 - final-message
 - power-state-change

# System and/or distro specific settings
# (not accessible to handlers/transforms)
system_info:
   # This will affect which distro class gets used
   distro: ubuntu
   # Default user name + that default users groups (if added/used)
   default_user:
     name: vagrant
     lock_passwd: false
     gecos: Vagrant
     groups: [adm, audio, cdrom, dialout, dip, floppy, netdev, plugdev, sudo, video]
     sudo: ["ALL=(ALL) NOPASSWD:ALL"]
     shell: /bin/bash
   # Other config here will be given to the distro class and/or path classes
   paths:
      cloud_dir: /var/lib/cloud/
      templates_dir: /etc/cloud/templates/
      upstart_dir: /etc/init/
   package_mirrors:
     - arches: [i386, amd64]
       failsafe:
         primary: http://archive.ubuntu.com/ubuntu
         security: http://security.ubuntu.com/ubuntu
       search:
         primary:
           - http://mirror.internode.on.net/pub/ubuntu/ubuntu
           - http://mirror.aarnet.edu.au/pub/ubuntu/archive
         security: []
     - arches: [armhf, armel, default]
       failsafe:
         primary: http://ports.ubuntu.com/ubuntu-ports
         security: http://ports.ubuntu.com/ubuntu-ports
   ssh_svcname: ssh
EOF

# this script *should* ensure that the interface completes its configuration
# before cloud-init attempts to print network configuration to the console
cat >/etc/network/if-up.d/000waitforit <<'EOF'
#!/bin/sh

LOG_FILE="/tmp/if-up.log"

echo -n `date  --iso-8601=ns` >> $LOG_FILE
echo ": IFACE $IFACE METHOD $METHOD ADDRFAM $ADDRFAM" >> $LOG_FILE

if [ "$IFACE" = "lo" ]; then
    echo -n `date  --iso-8601=ns` >> $LOG_FILE
    echo ": Skipping IP address wait on lo" >> $LOG_FILE
    exit 0
fi

if [ "$METHOD" = "auto" -o "$METHOD" = "dhcp" ]; then
    echo -n `date  --iso-8601=ns` >> $LOG_FILE
    echo ": $METHOD method detected, waiting for IP address" >> $LOG_FILE

    TIMEOUT=50

    until [ $TIMEOUT -eq 0 ]; do
        ADDRESS_COUNT=`ip addr show dev $IFACE | grep "$ADDRFAM " | grep -v 'fe80:' | wc -l`

        if [ "$ADDRESS_COUNT" -gt 0 ]; then
            echo -n `date  --iso-8601=ns` >> $LOG_FILE
            echo ": Detected IP address, exiting" >> $LOG_FILE
            exit 0
        fi

        TIMEOUT=$((TIMEOUT-1))
        sleep .1
    done

    echo -n `date  --iso-8601=ns` >> $LOG_FILE
    echo ": Timeout waiting for IP address" >> $LOG_FILE
    exit 1;
fi
EOF
chmod 0755 /etc/network/if-up.d/000waitforit

sed -i -e '/^start / s/$/ and static-network-up/' /etc/init/cloud-init.conf
