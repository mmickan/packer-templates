# Without this, Beaker (from Puppetlabs) creates an authorized_keys file
# with incorrect SELinux context and cannot log in as root
mkdir -p /root/.ssh
restorecon /root/.ssh
