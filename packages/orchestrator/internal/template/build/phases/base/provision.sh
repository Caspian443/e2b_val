#!/bin/sh
set -eu

echo "Starting provisioning script"

# echo "Making configuration immutable"
# {{ .BusyBox }} chattr +i /etc/resolv.conf

# Configure proxy if available from host
{{- if ne .HTTPProxy "" }}
echo "Configuring HTTP proxy: {{ .HTTPProxy }}"
export http_proxy="{{ .HTTPProxy }}"
export HTTP_PROXY="{{ .HTTPProxy }}"
{{- else }}
echo "No HTTP proxy configured - using direct connection"
{{- end }}

{{- if ne .HTTPSProxy "" }}
echo "Configuring HTTPS proxy: {{ .HTTPSProxy }}"
export https_proxy="{{ .HTTPSProxy }}"
export HTTPS_PROXY="{{ .HTTPSProxy }}"
{{- else }}
echo "No HTTPS proxy configured - using direct connection"
{{- end }}
# export http_proxy="http://183.207.7.174:32088"
# export https_proxy="http://183.207.7.174:32088"

# Configure apt proxy if HTTP_PROXY is set
{{- if ne .HTTPProxy "" }}
echo "Configuring apt proxy"
cat > /etc/apt/apt.conf.d/95proxies <<'EOFPROXY'
Acquire::http::Proxy "{{ .HTTPProxy }}";
{{- if ne .HTTPSProxy "" }}
Acquire::https::Proxy "{{ .HTTPSProxy }}";
{{- else }}
Acquire::https::Proxy "{{ .HTTPProxy }}";
{{- end }}
EOFPROXY
{{- else }}
echo "No apt proxy configured - using direct connection"
{{- end}}

cat > /etc/resolv.conf <<EOF
nameserver 8.8.8.8
EOF

echo "--- Network Diagnosis ---"
echo "Contents of /etc/resolv.conf:"
cat /etc/resolv.conf || echo "/etc/resolv.conf not found"
echo "---"
echo "Attributes of /etc/resolv.conf:"
lsattr /etc/resolv.conf || echo "/etc/resolv.conf not found or lsattr failed"
echo "---"
echo "IP address information:"
ip addr show
echo "---"
echo "Routing table:"
ip route show
echo "--- End Network Diagnosis ---"

# Install required packages if not already installed
PACKAGES="systemd systemd-sysv openssh-server sudo chrony linuxptp socat curl ca-certificates"
echo "Checking presence of the following packages: $PACKAGES"

MISSING=""

for pkg in $PACKAGES; do
    if ! dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "install ok installed"; then
        echo "Package $pkg is missing, will install it."
        MISSING="$MISSING $pkg"
    fi
done

if [ -n "$MISSING" ]; then
    echo "Missing packages detected, installing:$MISSING"

    # 替换为阿里云镜像源（国内访问快速）
    # 自动检测 Ubuntu 版本
    UBUNTU_CODENAME=$(lsb_release -cs 2>/dev/null || grep VERSION_CODENAME /etc/os-release | cut -d= -f2)
    if [ -n "$UBUNTU_CODENAME" ]; then
        echo "Replacing Ubuntu sources with Aliyun mirror (China) for $UBUNTU_CODENAME"
        cat > /etc/apt/sources.list <<EOF
deb http://mirrors.aliyun.com/ubuntu/ $UBUNTU_CODENAME main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ $UBUNTU_CODENAME-updates main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ $UBUNTU_CODENAME-backports main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ $UBUNTU_CODENAME-security main restricted universe multiverse


EOF
    else
        echo "Warning: Could not detect Ubuntu codename, keeping original sources"
    fi

    apt-get -q update
    DEBIAN_FRONTEND=noninteractive DEBCONF_NOWARNINGS=yes apt-get -qq -o=Dpkg::Use-Pty=0 install -y --no-install-recommends $MISSING
else
    echo "All required packages are already installed."
fi

echo "Setting up shell"
echo "export SHELL='/bin/bash'" >/etc/profile.d/shell.sh
echo "export PS1='\w \$ '" >/etc/profile.d/prompt.sh
echo "export PS1='\w \$ '" >>"/etc/profile"
echo "export PS1='\w \$ '" >>"/root/.bashrc"

echo "Use .bashrc and .profile"
echo "if [ -f ~/.bashrc ]; then source ~/.bashrc; fi; if [ -f ~/.profile ]; then source ~/.profile; fi" >>/etc/profile

echo "Remove root password"
passwd -d root

echo "Setting up chrony"
mkdir -p /etc/chrony
cat <<EOF >/etc/chrony/chrony.conf
refclock PHC /dev/ptp0 poll 2 dpoll 2
EOF

# Add a proxy config, as some environments expects it there (e.g. timemaster in Node Dockerimage)
echo "include /etc/chrony/chrony.conf" >/etc/chrony.conf

# Set chrony to run as root
mkdir -p /etc/systemd/system/chrony.service.d
cat <<EOF >/etc/systemd/system/chrony.service.d/override.conf
[Service]
ExecStart=
ExecStart=/usr/sbin/chronyd
User=root
Group=root
EOF

echo "Setting up SSH"
mkdir -p /etc/ssh
cat <<EOF >>/etc/ssh/sshd_config
PermitRootLogin yes
PermitEmptyPasswords yes
PasswordAuthentication yes
EOF

echo "Configuring swap to 128 MiB"
mkdir -p /swap
fallocate -l 128M /swap/swapfile
chmod 600 /swap/swapfile
mkswap /swap/swapfile

echo "Increasing inotify watch limit"
echo 'fs.inotify.max_user_watches=65536' | tee -a /etc/sysctl.conf

echo "Don't wait for ttyS0 (serial console kernel logs)"
# This is required when the Firecracker kernel args has specified console=ttyS0
systemctl mask serial-getty@ttyS0.service

echo "Disable network online wait"
systemctl mask systemd-networkd-wait-online.service

echo "Disable systemd-networkd to preserve kernel ip= configuration"
systemctl disable systemd-networkd.service
systemctl mask systemd-networkd.service

echo "Disable system first boot wizard"
# This was problem with Ubuntu 24.04, that differently calculate wizard should be called
# and Linux boot was stuck in wizard until envd wait timeout
systemctl mask systemd-firstboot.service

# Clean machine-id from Docker
rm -rf /etc/machine-id

echo "Linking systemd to init"
ln -sf /lib/systemd/systemd /usr/sbin/init

echo "Unlocking immutable configuration"
{{ .BusyBox }} chattr -i /etc/resolv.conf

echo "Finished provisioning script"

# Delete itself
rm -rf /etc/init.d/rcS
rm -rf /usr/local/bin/provision.sh

# Report successful provisioning
printf "0" > "{{ .ResultPath }}"
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                