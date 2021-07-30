#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
cat << "EOF"
Shadowsocks-libev + simple-obfs For Denbian 一键编译安装

EOF

[ $(id -u) != "0" ] && { echo "错误：必须 root 权限才能运行此脚本!"; exit 1; }
if [[ ${is_auto} != "y" ]]; then
	echo "按 Y 继续安装过程，或按其他任意键退出."
	read is_install
	if [[ ${is_install} != "y" && ${is_install} != "Y" ]]; then
    	echo -e "安装已取消..."
    	exit 0
	fi
fi
echo "检查是否已安装 Shadowsocks-libev + simple-obfs..."

if [ -d "/root/shadowsocks-libev" ]; then
	while :; do echo
		echo -n "服务器已安装 Shadowsocks-libev + simple-obfs！继续安装，之前的所有配置都将丢失！?(Y/N)"
		read is_clean_old
		if [[ ${is_clean_old} != "y" && ${is_clean_old} != "Y" && ${is_clean_old} != "N" && ${is_clean_old} != "n" ]]; then
			echo -n "请输入 Y 或 N !"
		elif [[ ${is_clean_old} == "y" || ${is_clean_old} == "Y" ]]; then
			rm -rf /root/shadowsocks-libev
			rm -rf /etc/systemd/system/shadowsocks.service
			rm -rf /usr/bin/ss-server
			rm -rf /usr/bin/ss-local
			rm -rf /usr/bin/ss-manager
			rm -rf /usr/bin/ss-redir
			rm -rf /usr/bin/ss-nat
			rm -rf /usr/bin/ss-tunnel
			break
		else
			exit 0
		fi
	done
fi
echo "检查更新及安装Shadowsocks-libev + simple-obfs..."

apt update -y && apt upgrade -y && apt install git -y
git clone https://github.com/shadowsocks/shadowsocks-libev.git
cd shadowsocks-libev
git submodule update --init --recursive
apt-get install -y --no-install-recommends autoconf automake \
debhelper pkg-config asciidoc xmlto libpcre3-dev apg pwgen rng-tools \
libev-dev libc-ares-dev dh-autoreconf libsodium-dev libmbedtls-dev
./autogen.sh && ./configure --prefix=/usr && make
make install
echo "HRNGDEVICE=/dev/urandom" | tee /etc/default/rng-tools
apt-get install -y rng-tools
service rng-tools restart
systemctl stop rng-tools
apt-get install -y --no-install-recommends build-essential autoconf libtool libssl-dev libpcre3-dev libev-dev asciidoc xmlto automake
git clone https://github.com/shadowsocks/simple-obfs.git
cd simple-obfs
git submodule update --init --recursive
./autogen.sh
./configure && make
make install
mkdir -p /etc/shadowsocks-libev
wget https://raw.githubusercontent.com/amcjcy/arc/main/one/config.json
mv config.json /etc/shadowsocks-libev/
wget https://raw.githubusercontent.com/amcjcy/arc/main/one/shadowsocks.service
mv shadowsocks.service /etc/systemd/system/
echo "echo 3 > /proc/sys/net/ipv4/tcp_fastopen" >> /etc/rc.local
echo "* soft nofile 512000" >> /etc/security/limits.conf
echo "* hard nofile 512000" >> /etc/security/limits.conf
echo "ulimit -n 51200">>/etc/profile
rm -rf /etc/sysctl.conf
wget https://raw.githubusercontent.com/amcjcy/arc/main/one/sysctl.conf
mv sysctl.conf /etc/

do_service(){
	echo "正在启动 Shadowsocks-libev + simple-obfs ..."
	systemctl daemon-reload && systemctl enable shadowsocks && systemctl start shadowsocks
}
while :; do echo
	echo -n "是否要将 Shadowsocks-libev + simple-obfs 加入开机自动启动?(Y/N)"
	read is_service
	if [[ ${is_service} != "y" && ${is_service} != "Y" && ${is_service} != "N" && ${is_service} != "n" ]]; then
		echo -n "错误！请输入 Y 或 N"
	else
		break
	fi
done
if [[ ${is_service} == "y" || ${is_service} == "Y" ]]; then
	do_service
fi
echo "系统需要重启才能完成安装，按 Y 重启，或按任意键退出."
read is_reboot
if [[ ${is_reboot} == "y" || ${is_reboot} == "Y" ]]; then
  reboot
else
  echo -e "已取消重启..."
	exit 0
fi
