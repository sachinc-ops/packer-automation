#/bin/bash

#================================================================
# Amazon Linux 2 / CentOS-7.x / RHEL-7.x OS Hardening Script
# Author : Sachin.C
#================================================================

# Exit on error
set -e

run_shell() {

# Install basic packages
sudo yum install -y -d1 vim unzip lsof gcc nfs-utils

# Removing unwanted services
sudo yum remove -y -d1 postfix rsync firewalld || true

# Masking unwanted services
echo "Masking unwanted services"
masked_services=(
    nfs-server
    rpcbind
    rpcbind-socket
    firewalld
)
for masked_service in ${masked_services[@]}; do
    sudo systemctl --now mask $masked_service
    sudo systemctl daemon-reload
done

# Disabling SELinux
echo "Disabling SELinux"
sudo sed -i "s/SELINUX=enforcing/SELINUX=disabled/" /etc/selinux/config

# Resticting Cron access
echo "Resticting Cron access"
echo "root" | sudo tee /etc/cron.allow > /dev/null

# Enabling GPG Check on All Repositories
echo "Enabling GPG Check on All Repositories"
sudo sed -i  's/gpgcheck=0/gpgcheck=1/g' /etc/yum.repos.d/*

# Updating permissions on  world-writable files & folders
echo "Updating permissions on  world-writable files & folders"
sudo df --local -P | awk {'if (NR!=1) print $6'} | xargs -I '{}' sudo find '{}' -xdev -type d -perm -0002 2>/dev/null | xargs sudo chmod a+t
sudo find /var/log -type f -exec chmod g-wx,o-rwx '{}' + -o -type d -exec chmod g-wx,o-rwx '{}' +

# Updating Boot Loader Permission
echo "Updating Boot Loader Permission"
sudo chown root:root /boot/grub2/grub.cfg && sudo chmod og-rwx /boot/grub2/grub.cfg
[[ -f /boot/grub2/user.cfg ]] && (sudo chown root:root /boot/grub2/user.cfg ; sudo chmod og-rwx /boot/grub2/user.cfg)

# Disable IPv6
echo "Disable IPv6"
sudo sed -i 's/udp6/#udp6/' /etc/netconfig || true
sudo sed -i 's/tcp6/#tcp6/' /etc/netconfig || true
sudo sed -i '/localhost6/d' /etc/hosts

# Fine tuning kernel parameters
echo "Fine tuning kernel parameters"
disabled_kernel_params=(
    net.ipv4.conf.all.send_redirects
    net.ipv4.conf.default.send_redirects
    net.ipv4.conf.all.accept_source_route
    net.ipv4.conf.default.accept_source_route
    net.ipv4.conf.all.accept_redirects
    net.ipv4.conf.default.accept_redirects
    net.ipv4.conf.all.secure_redirects
    net.ipv4.conf.default.secure_redirects
    net.ipv6.conf.all.accept_ra
    net.ipv6.conf.default.accept_ra
)
enabled_kernel_params=(
    net.ipv4.conf.all.log_martians
    net.ipv4.conf.default.log_martians
    net.ipv4.icmp_echo_ignore_broadcasts
    net.ipv4.icmp_ignore_bogus_error_responses
    net.ipv4.conf.all.rp_filter
    net.ipv4.conf.default.rp_filter
    net.ipv4.tcp_syncookies
    net.ipv6.conf.all.disable_ipv6
    net.ipv6.conf.default.disable_ipv6
)

for disabled_param in ${disabled_kernel_params[@]}; do
    echo "${disabled_param} = 0" | sudo tee -a /etc/sysctl.conf > /dev/null
    sudo  sysctl -w ${disabled_param}=0
done
for enabled_param in ${enabled_kernel_params[@]}; do
    echo "${enabled_param} = 1" | sudo tee -a /etc/sysctl.conf > /dev/null
    sudo sysctl -w ${enabled_param}=1
done
sudo tee -a /etc/sysctl.conf > /dev/null << EOF
vm.swappiness = 10
fs.suid_dumpable = 0
kernel.randomize_va_space = 2
EOF
grep -Els '^s*net.ipv4.ip_forwards*=s*1' /etc/sysctl.conf /etc/sysctl.d/*.conf /usr/lib/sysctl.d/*.conf /run/sysctl.d/*.conf | while read filename; do sudo sed -ri 's/^s*(net.ipv4.ip_forwards*)(=)(s*S+b).*$/# *REMOVED* 1/' $filename; done; sudo sysctl -w net.ipv4.ip_forward=0; sudo sysctl -w net.ipv4.route.flush=1
grep -Els '^s*net.ipv6.conf.all.forwardings*=s*1' /etc/sysctl.conf /etc/sysctl.d/*.conf /usr/lib/sysctl.d/*.conf /run/sysctl.d/*.conf | while read filename; do sudo sed -ri 's/^s*(net.ipv6.conf.all.forwardings*)(=)(s*S+b).*$/# *REMOVED* 1/' $filename; done; sudo sysctl -w net.ipv6.conf.all.forwarding=0; sudo sysctl -w net.ipv6.route.flush=1


# Updating sudoers
echo "Updating sudoers"
sudo tee -a /etc/sudoers > /dev/null << EOF
Defaults  use_pty
Defaults  logfile="/var/log/sudo.log"
EOF

# Adding Login banners
echo "Adding Login banners"
sudo tee /etc/motd > /dev/null << EOF
#########################################################################

WARNING:  Unauthorized access to this system is forbidden and will be
prosecuted by law. By accessing this system, you agree that your actions
may be monitored if unauthorized usage is suspected.

#########################################################################
EOF
echo "Authorized uses only. All activity may be monitored and reported..!" | sudo tee /etc/issue /etc/issue.net > /dev/null

# Harden SSH
echo "Harden SSH"
sudo tee -a /etc/ssh/sshd_config > /dev/null << EOF
# Below Configurations are added by OS Hardening script
AddressFamily inet
MaxAuthTries 4
Ciphers aes128-ctr,aes192-ctr,aes256-ctr
MACs hmac-sha2-256,hmac-sha2-512
PermitRootLogin no
ClientAliveInterval 300
ClientAliveCountMax 3
LoginGraceTime 60
maxstartups 10:30:60
Banner /etc/issue.net
###
EOF
sudo sed -i 's/X11Forwarding yes/X11Forwarding no/g' /etc/ssh/sshd_config
sudo systemctl restart sshd

# Unload Filesystem Module
echo "Unload Filesystem Module"
modules=(
    cramfs
    udf
    usb-storage
)
for module in ${modules[@]}; do
    echo "install $module /bin/true"  | sudo tee /etc/modprobe.d/${module}.conf > /dev/null
    sudo rmmod $module || true
done

# Restricting Coredump
echo "Restricting Coredump"
echo "* hard core 0" | sudo tee -a /etc/security/limits.conf > /dev/null
echo "fs.suid_dumpable = 0" | sudo tee -a /etc/sysctl.conf > /dev/null
sudo sysctl -w fs.suid_dumpable=0
sudo tee -a /etc/systemd/coredump.conf > /dev/null <<EOF
Storage=none
ProcessSizeMax=0
EOF
sudo systemctl daemon-reload

# Enabling /tmp mount
echo "Enabling /tmp mount"
sudo systemctl unmask tmp.mount
sudo cp /usr/lib/systemd/system/tmp.mount /etc/systemd/system/tmp.mount
sudo systemctl enable tmp.mount
sudo systemctl start tmp.mount
echo "tmpfs      /dev/shm    tmpfs   defaults,noexec,nodev,nosuid,seclabel   0 0" | sudo tee -a /etc/fstab > /dev/null
sudo mount -o remount,noexec,nodev,nosuid /dev/shm

# Restricting su command
echo "Restricting su command"
sudo groupadd sugroup
sudo sed -i '7 i auth required pam_wheel.so use_uid group=sugroup' /etc/pam.d/su

# Configuring rsyslog
echo "Configuring rsyslog"

echo '$FileCreateMode 0640' | sudo tee -a /etc/rsyslog.conf > /dev/null
sudo sed -i 's/local7/#local7/' /etc/rsyslog.conf || true
sudo sed -i 's/authpriv/#authpriv/' /etc/rsyslog.conf || true
sudo tee -a /etc/rsyslog.conf > /dev/null << EOF

auth,authpriv.*                          /var/log/secure
mail.info                               -/var/log/mail.info
mail.warning                            -/var/log/mail.warn
mail.err                                 /var/log/mail.err
news.crit                               -/var/log/news/news.crit
news.err                                -/var/log/news/news.err
news.notice                             -/var/log/news/news.notice

*.=warning;*.=err                       -/var/log/warn
*.crit                                   /var/log/warn
*.*;mail.none;news.none                 -/var/log/messages

local0,local1.*                         -/var/log/localmessages
local2,local3.*                         -/var/log/localmessages
local4,local5.*                         -/var/log/localmessages
local6,local7.*                         -/var/log/localmessages
EOF
sudo systemctl restart rsyslog

# Enabling journald logging
echo "Enabling journald logging"
sudo tee -a /etc/systemd/journald.conf > /dev/null << EOF
ForwardToSyslog=yes
Compress=yes
Storage=persistent
EOF

# Ensure default user shell timeout is configured
sudo tee -a  /etc/profile << EOF  
TMOUT=900
readonly TMOUT
export TMOUT
EOF

# Ensure default user umask is configured - system wide umask 
sudo sed -i 's/umask 022/umask 027/g' /etc/bashrc
sudo sed -i 's/umask 002/umask 027/g' /etc/bashrc
sudo sed -i 's/umask 002/umask 027/g' /etc/profile
sudo sed -i 's/umask 022/umask 027/g' /etc/profile

# Configuring Auditd Logging
echo "Configuring Auditd Logging"
sudo sed -i 's/space_left_action = SYSLOG/space_left_action = email/g' /etc/audit/auditd.conf
sudo sed -i 's/admin_space_left_action = SUSPEND/admin_space_left_action = halt/g'  /etc/audit/auditd.conf
sudo sed -i 's/max_log_file_action = ROTATE/max_log_file_action = keep_logs/g' /etc/audit/auditd.conf

sudo tee -a /etc/audit/rules.d/audit.rules > /dev/null << EOF 
-a always,exit -F arch=b64 -S adjtimex -S settimeofday -k time-change
-a always,exit -F arch=b32 -S adjtimex -S settimeofday -S stime -k time-change
-a always,exit -F arch=b64 -S clock_settime -k time-change
-a always,exit -F arch=b32 -S clock_settime -k time-change
-w /etc/localtime -p wa -k time-change
####
-w /etc/group -p wa -k identity
-w /etc/passwd -p wa -k identity
-w /etc/gshadow -p wa -k identity
-w /etc/shadow -p wa -k identity
-w /etc/security/opasswd -p wa -k identity
####
-a always,exit -F arch=b64 -S sethostname -S setdomainname -k system-locale
-a always,exit -F arch=b32 -S sethostname -S setdomainname -k system-locale
-w /etc/issue -p wa -k system-locale
-w /etc/issue.net -p wa -k system-locale
-w /etc/hosts -p wa -k system-locale
-w /etc/sysconfig/network -p wa -k system-locale
-w /etc/sysconfig/network-scripts/ -p wa -k system-locale
####
-w /etc/selinux/ -p wa -k MAC-policy
-w /usr/share/selinux/ -p wa -k MAC-policy
####
-w /var/log/lastlog -p wa -k logins
-w /var/run/faillock/ -p wa -k logins
####
-w /var/run/utmp -p wa -k session
-w /var/log/wtmp -p wa -k logins
-w /var/log/btmp -p wa -k logins
################################################

-a always,exit -F arch=b64 -S chmod -S fchmod -S fchmodat -F auid>=1000 -F auid!=4294967295 -k perm_mod
-a always,exit -F arch=b32 -S chmod -S fchmod -S fchmodat -F auid>=1000 -F auid!=4294967295 -k perm_mod
-a always,exit -F arch=b64 -S chown -S fchown -S fchownat -S lchown -F auid>=1000 -F auid!=4294967295 -k perm_mod
-a always,exit -F arch=b32 -S chown -S fchown -S fchownat -S lchown -F auid>=1000 -F auid!=4294967295 -k perm_mod
-a always,exit -F arch=b64 -S setxattr -S lsetxattr -S fsetxattr -S removexattr -S lremovexattr -S fremovexattr -F auid>=1000 -F auid!=4294967295 -k perm_mod
-a always,exit -F arch=b32 -S setxattr -S lsetxattr -S fsetxattr -S removexattr -S lremovexattr -S fremovexattr -F auid>=1000 -F auid!=4294967295 -k perm_mod
####
-a always,exit -F arch=b64 -S mount -F auid>=1000 -F auid!=4294967295 -k mounts
-a always,exit -F arch=b32 -S mount -F auid>=1000 -F auid!=4294967295 -k mounts
####
-a always,exit -F arch=b64 -S unlink -S unlinkat -S rename -S renameat -F auid>=1000 -F auid!=4294967295 -k delete
-a always,exit -F arch=b32 -S unlink -S unlinkat -S rename -S renameat -F auid>=1000 -F auid!=4294967295 -k delete
####
-w /etc/sudoers -p wa -k scope
-w /etc/sudoers.d/ -p wa -k scope
####
-w /var/log/sudo.log -p wa -k actions
####
-w /sbin/insmod -p x -k modules
-w /sbin/rmmod -p x -k modules
-w /sbin/modprobe -p x -k modules
-a always,exit -F arch=b64 -S init_module -S delete_module -k modules
####
-a always,exit -F arch=b64 -S creat -S open -S openat -S truncate -S ftruncate -F exit=-EACCES -F auid>=1000 -F auid!=4294967295 -k access
-a always,exit -F arch=b32 -S creat -S open -S openat -S truncate -S ftruncate -F exit=-EACCES -F auid>=1000 -F auid!=4294967295 -k access
-a always,exit -F arch=b64 -S creat -S open -S openat -S truncate -S ftruncate -F exit=-EPERM -F auid>=1000 -F auid!=4294967295 -k access
-a always,exit -F arch=b32 -S creat -S open -S openat -S truncate -S ftruncate -F exit=-EPERM -F auid>=1000 -F auid!=4294967295 -k access
EOF

sudo /sbin/service auditd reload

# Setting Amazon Time Sync service
echo "Setting Amazon Time Sync service"
sudo sed -i '/^server/s/^/#/' /etc/chrony.conf
echo "server 169.254.169.123 prefer iburst minpoll 4 maxpoll 4" | sudo tee -a /etc/chrony.conf > /dev/null
sudo sed -i '/^OPTIONS/s/^/#OPTIONS/' /etc/sysconfig/chronyd
echo 'OPTIONS="-u chrony -4"' | sudo tee -a /etc/sysconfig/chronyd > /dev/null
sudo systemctl restart chronyd

# Ensure auditing for processes that start prior to auditd is enabled
sudo sed -i 's/GRUB_CMDLINE_LINUX/#GRUB_CMDLINE_LINUX/g' /etc/default/grub
sudo sed -i 's/#GRUB_CMDLINE_LINUX_DEFAULT/GRUB_CMDLINE_LINUX_DEFAULT/g' /etc/default/grub
sudo tee -a /etc/default/grub > /dev/null << EOF
GRUB_CMDLINE_LINUX="console=ttyS0,115200n8 console=tty0 net.ifnames=0 rd.blacklist=nouveau crashkernel=auto audit=1"
EOF
sudo grub2-mkconfig -o /boot/grub2/grub.cfg

# Enabling FIPS Configuration
echo "Enabling FIPS Configuration"
sudo yum install -y -d1 dracut-fips                                             # FIPS package (https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/6/html/security_guide/sect-security_guide-federal_standards_and_regulations-federal_information_processing_standard)
grep -qw aes /proc/cpuinfo && sudo yum install -y -d1 dracut-fips-aesni         # Package for CPUs with AES New Instructions (AES-NI) support
sudo mv -v /boot/initramfs-$(uname -r).img{,.bak}                               # Backup existing initramfs
sudo dracut -f -v                                                               # Recreate the initramfs file
sudo su -c 'grubby --update-kernel=$(grubby --default-kernel) --args=fips=1'    # Edit kernel command-line to include the fips=1 argument

# Rebooting server
echo " Rebooting Server.." && sudo reboot

}

skip_shell () {
    echo "Skipping Bootstrap Script.."
}
[[ "$INPUT" == "run" ]] && run_shell || skip_shell
