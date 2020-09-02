
image_name=${1:-"fedora:31"}

systemctl mask \
	auditd.service\
	console-getty.service\
	dev-hugepages.mount\
	dnf-makecache.service\
	getty.target\
	lvm2-lvmetad.service\
	sys-fs-fuse-connections.mount\
	systemd-logind.service\
	systemd-remount-fs.service\
	systemd-udev-hwdb-update.service\
	systemd-udevd.service\
	systemd-vconsole-setup.service


if echo $image_name | grep ubi8
then

	# add needed repo

	cat > /etc/yum.repos.d/centos-appstream.repo <<EOF
[centos-appstream]
name=centos-appstream
baseurl=http://mirror.centos.org/centos/8/AppStream/x86_64/os/
enabled=1
gpgcheck=0
skip_if_unavailable=1
EOF

	cat > /etc/yum.repos.d/centos-baseos.repo <<EOF
[centos-baseos]
name=centos-baseos
baseurl=http://mirror.centos.org/centos/8/BaseOS/x86_64/os/
enabled=1
gpgcheck=0
skip_if_unavailable=1
EOF

	cat > /etc/yum.repos.d/centos-powertools.repo <<EOF
[centos-powertools]
name=centos-powertools
baseurl=http://mirror.centos.org/centos/8/PowerTools/x86_64/os/
enabled=1
gpgcheck=0
skip_if_unavailable=1
EOF


	dnf -y --skip-broken install automake make gcc autoconf openssl-devel \
		python3 libtool openssl python3-pip \
		net-tools.x86_64 uuid.x86_64 iproute.x86_64 dnf-utils libreswan \
		conntrack-tools nmap ninja-build meson libcap-devel gettext-devel libxslt git iproute
	dnf remove -y iputils

	git clone https://github.com/iputils/iputils.git
	pushd iputils
	./configure && make && make install
	popd


elif echo $image_name | grep ubi7
then

	# add needed repo
	rpm -ivh https://download-cc-rdu01.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
	cat > /etc/yum.repos.d/centos-os.repo <<EOF
[centos-os]
name=centos-os
baseurl=http://mirror.centos.org/centos/7/os/x86_64/
enabled=1
gpgcheck=0
skip_if_unavailable=1
EOF
	yum -y --skip-broken install automake make gcc autoconf openssl-devel \
		python3 libtool openssl python3-pip \
		net-tools.x86_64 uuid.x86_64 iproute.x86_64 dnf-utils libreswan \
		conntrack-tools nmap ninja-build meson libcap-devel gettext-devel libxslt git iproute
	yum remove -y iputils

	# install iputils from source, as -W 0.1 is not supported
	git clone https://github.com/iputils/iputils.git
	pushd iputils
	./configure && make && make install
	popd
else
	systemctl mask docker-storage-setup.service
	yum install docker pacemaker pcs -y --skip-broken
	systemctl enable docker.service
	systemctl enable pcsd.service

	yum -y --skip-broken install automake make gcc autoconf openssl-devel \
		python3 libtool openssl python3-pip \
		net-tools.x86_64 uuid.x86_64 iproute.x86_64 dnf-utils libreswan \
		conntrack-tools nmap iputils which dhclient

	# Default storage to vfs.  overlay will be enabled at runtime if available
	echo "DOCKER_STORAGE_OPTIONS=--storage-driver vfs" > /etc/sysconfig/docker-storage
	# Generate variation of dhclient-script that we can use for fake vm namespaces
	mkdir -pv /bin
	/tmp/generate_dhclient_script_for_fullstack.sh /
fi

yum -y --skip-broken install\
	glibc-langpack-en\
	iptables\
	openssh-clients\
	openssh-server\
	resource-agents\
	tcpdump\
	dhclient\
	which\
	fping\
	perf\
	git\
	file\
	lksctp-tools-devel\
	hostname


