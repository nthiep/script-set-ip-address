#!/bin/bash
##################################################
# Name: configuration.sh
# Description: File cau hinh ip va lay dia chi ip tren remote host
#
##################################################
# Set Script Variables
#
# dia chi file cau hinh Debian hoac Ubuntu
NETWORK_CONFIG_DEBIAN="/home/hiep/kichban/TieuLuanKB/interfaces"
# dia chi file cau hinh tren redhat fedora centos
#NETWORK_CONFIG_REDHAT="/etc/sysconfig/network-scripts/ifcfg-"
NETWORK_CONFIG_REDHAT="/home/hiep/kichban/TieuLuanKB/ifcfg-"
# dia chi file luu lai cac buoc cau hinh
LOG_FILE="settingIpLog.txt"
##################################################
# Ham lay dia chi ip tu lenh ifconfig neu hien tai dang su dung ip dong
#
getIfconfigInfo(){
	[ $# -eq 0 ] && return 1
	ip=$(ifconfig $1  2> /dev/null|grep "inet addr"|cut -f 2 -d ":"|cut -f 1 -d " ")
	netmask=$(ifconfig $1  2> /dev/null|grep "Mask"|cut -f 4 -d ":")
	[ -n "$ip" -a -n "$netmask" ] && echo "$ip:$netmask" || echo ""
}

##################################################
# Ham lay dia chi ip tu lenh ifconfig neu hien tai dang su dung ip dong
# hoac tu file cau hinh tren may Redhat centos
#
getIpInfoRedhat(){
	echo "config getIpInfoRedhat: $1" >> $LOG_FILE	
	[ -f "$NETWORK_CONFIG_REDHAT$1" ] || return 1
	[ $# -eq 0 ] && return 1
	ip=$(sed -n 's/IPADDR=//p'  $NETWORK_CONFIG_REDHAT$1|sed -e 's/^[[:space:]]*//')
	netmask=$(sed -n 's/NETMASK=//p'  $NETWORK_CONFIG_REDHAT$1|sed -e 's/^[[:space:]]*//')

	echo "config getIpInfoRedhat: ip:$ip" >> $LOG_FILE
	echo "config getIpInfoRedhat: netmask:$netmask" >> $LOG_FILE
	[ -n "$ip" -a -n "$netmask" ] && { echo "$ip:$netmask"; return 0; }
	ipInfo=$(getIfconfigInfo $1)
	echo "config getIpInfoRedhat: ipInfo:$ipInfo" >> $LOG_FILE
	[ -n "$ipInfo" ] && echo $ipInfo || return 1
}

##################################################
# Ham lay string cau hinh static hay dhcp cho may debian
#
getConfigIfStringDebian(){
	[ "$2" == "dhcp" ] && printf "iface $1 inet dhcp"'\\n' || printf "iface $1 inet static"'\\n'
	return 0
}

##################################################
# Ham lay string cau hinh ip, netmask, gateway cho may debian
#
getConfigIpStringDebian(){
	[ -n "$1" ] && printf '\\t'"address $1"'\\n'
	[ -n "$2" ] && printf '\\t'"netmask $2"'\\n'
	[ -n "$3" ] && printf '\\t'"gateway $3"'\\n'
}

##################################################
# Ham cau hinh ip cho may debian
#
setIpDebian(){
	# Kiem tra neu file cau hinh chua tao hoac khong co interface cau hinh
	#
	[ -f "$NETWORK_CONFIG_DEBIAN" ] && grep -q "iface $1" $NETWORK_CONFIG_DEBIAN || \
	{ echo "iface $1" >> $NETWORK_CONFIG_DEBIAN; echo "config setIpDebian: Config file $1 not found" >> $LOG_FILE; }	
	
	# cau lenh sed xoa tat ca cac dong cau hinh trong interface
	#
	sed -i.bak "/iface $1/,/iface/{//!d}" $NETWORK_CONFIG_DEBIAN
	
	# cau lenh sed cau hinh dhcp
	#
	[ "$2" == "dhcp" ] && { sed -i "s/iface $1.*/$(getConfigIfStringDebian $1 $2)/" $NETWORK_CONFIG_DEBIAN; return 0; }
	# ghi vao file log
	echo "s/iface $1.*/$(getConfigIfStringDebian $1 $2)$(getConfigIpStringDebian $3 $4 $5)/" >> $LOG_FILE 
	# cau lenh sed cau hinh static
	sed -i "s/iface $1.*/$(getConfigIfStringDebian $1 $2)$(getConfigIpStringDebian $3 $4 $5)/" $NETWORK_CONFIG_DEBIAN
	return 0

}

##################################################
# Ham cau hinh ip cho may redhat
#
setIpRedhat(){
	[ -f "$NETWORK_CONFIG_REDHAT$1" ] || echo "" > $NETWORK_CONFIG_REDHAT$1
	[ -n "$2" ] && { grep -q "^BOOTPROTO=" $NETWORK_CONFIG_REDHAT$1 && sed "s/^BOOTPROTO=.*/BOOTPROTO=$2/" -i $NETWORK_CONFIG_REDHAT$1 || sed "$ a\BOOTPROTO=$2" -i $NETWORK_CONFIG_REDHAT$1; }
	[ -n "$3" ] && { grep -q "^IPADDR=" $NETWORK_CONFIG_REDHAT$1 && sed "s/^IPADDR=.*/IPADDR=$3/" -i $NETWORK_CONFIG_REDHAT$1 || sed "$ a\IPADDR=$3" -i $NETWORK_CONFIG_REDHAT$1; }
	[ -n "$4" ] && { grep -q "^NETMASK=" $NETWORK_CONFIG_REDHAT$1 && sed "s/^NETMASK=.*/NETMASK=$4/" -i $NETWORK_CONFIG_REDHAT$1 || sed "$ a\NETMASK=$4" -i $NETWORK_CONFIG_REDHAT$1; }
	[ -n "$5" ] && { grep -q "^GATEWAY=" $NETWORK_CONFIG_REDHAT$1 && sed "s/^GATEWAY=.*/GATEWAY=$5/" -i $NETWORK_CONFIG_REDHAT$1 || sed "$ a\GATEWAY=$5" -i $NETWORK_CONFIG_REDHAT$1; }
}

##################################################
# Ham lay dia chi ip tren may debian
#
getIpInfoDebian(){
	[ $# -eq 0 ] && return 1
	# lenh sed lay dia chi ip
	ip=$(sed -n "/iface $1/,/iface/ s/address//p"  $NETWORK_CONFIG_DEBIAN|sed -e 's/^[[:space:]]*//')
	# lenh sed lay subnetmask
	netmask=$(sed -n "/iface $1/,/iface/ s/netmask//p"  $NETWORK_CONFIG_DEBIAN|sed -e 's/^[[:space:]]*//')
	# ghi log file
	echo "config getIpInfoDebian: IP:$ip" >> $LOG_FILE
	echo "config getIpInfoDebian: netmask:$netmask" >> $LOG_FILE
	# kiem tra ip co ton tai trong file cau hinh
	[ -n "$ip" -a -n "$netmask" ] && { echo "$ip:$netmask"; return 0; }
	# lay dia chi ip tu lenh ifconfig
	ipInfo=$(getIfconfigInfo $1)
	# ghi log file
	echo "config getIpInfoDebian: ipInfo:$ipInfo" >> $LOG_FILE
	[ -n "$ipInfo" ] && echo $ipInfo || return 1
}

##################################################
# Ham kiem tra phien ban he dieu hanh co phai Debian hay Ubuntu
#
isDebianOS(){
	local VERSION_FILE="/proc/version"
	version=$(cat $VERSION_FILE)
	[[ "$version" == *"ubuntu"* ]] || [[ "$version" == *"debian"* ]] \
	&& { echo "config isDebianOS: Debian OS" >> $LOG_FILE; return 0; } \
	|| { echo "config isDebianOS: Not Debian OS" >> $LOG_FILE; return 1; }
}

##################################################
# Cau hinh IP
#
settingIp(){
	result=$(isDebianOS && setIpDebian $1 $2 $3 $4 $5 || setIpRedhat $1 $2 $3 $4 $5)
	ifdown eth0 && ifup eth0
	echo "config settingIp: $result" >> $LOG_FILE; 
}

##################################################
# Lay thong tin IP cu
#
getInfoIp(){
	# nau may la Debian hay Ubuntu thi goi ham getIpInfoDebian
	# nguoc lai goi getIpInfoRedhat
	isDebianOS && result=$(getIpInfoDebian $1) || result=$(getIpInfoRedhat $1)
	echo $result
	echo "config getInfoIp: $result" >> $LOG_FILE; 
}

##################################################
# Ham main
#
main(){
		[ "$3" == "static" -o "$3" == "dhcp" ] && settingIp $2 $3 $4 $5 $6 \
		&& echo  $1:$2:$(getInfoIp $2):$3:$4:$5:$6\
		|| echo  $1:$2:$(getInfoIp $2)
}
echo "**********" $(date -R) >> $LOG_FILE
echo "config value: $1 $2 $3 $4 $5 $6" >> $LOG_FILE
result=$(main $1 $2 $3 $4 $5 $6)
echo $result
echo "config result: $result" >> $LOG_FILE