#!/bin/bash
##################################################
# Name: configuration.sh
# Description: File cau hinh ip va lay dia chi ip tren remote host
#
##################################################
# Set Script Variables
#
# dia chi file cau hinh Debian hoac Ubuntu
#NETWORK_CONFIG_DEBIAN="/home/hiep/kichban/TieuLuanKB/ConfigFile/interfaces"
NETWORK_CONFIG_DEBIAN="/etc/network/interfaces"
# dia chi file luu lai cac buoc cau hinh
LOG_FILE="settingIpLog.txt"
##################################################
# Ham lay dia chi ip tu lenh ifconfig neu hien tai dang su dung ip dong
#
getIfconfigInfo(){
	[ $# -eq 0 ] && return 1
	ip=$(ifconfig $1  2> /dev/null|grep "inet addr"|cut -f 2 -d ":"|cut -f 1 -d " ")
	netmask=$(ifconfig $1  2> /dev/null|grep "Mask"|cut -f 4 -d ":")
	[ -n "$ip" -a -n "$netmask" ] && echo "dhcp:$ip:$netmask" || echo ""
}
# Ham lay dia chi default gateway
#
getDefaultGateway(){
	[ -n "$(route |grep UG|sed -e 's/[[:space:]]\+/ /g'|cut -f2 -d' ')" ] || echo "-"
}

# Ham dat default gateway
#
setDefaultGateway(){
	[ $# -eq 0 ] && return 1
	oldgateway=$(getDefaultGateway)
	[ -n "$oldgateway" ] && route del default gw $oldgateway
	route add default gw $1
}

##################################################
# Ham lay string cau hinh ip, netmask, gateway cho may debian
#
getConfigIpStringDebian(){
	[ "$2" == "dhcp" ] && { printf '\\n'"iface $1 inet dhcp"'\\n'"auto $1"'\\n'; return 0; } || printf '\\n'"iface $1 inet static"'\\n'
	[ -n "$3" ] && printf '\\t'"address $3"'\\n'
	[ -n "$4" ] && printf '\\t'"netmask $4"'\\n'
	[ -n "$5" ] && printf '\\t'"gateway $5"'\\n'
	printf "auto $1"'\\n'
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
	sed -i$(date +'_%m-%d-%Y_%k:%M:%S:%N_%Z%z').bak "/iface $1/,/iface/{//!d}" $NETWORK_CONFIG_DEBIAN
	sed -i "/iface $1/,/\n/{//!d}" $NETWORK_CONFIG_DEBIAN
	
	# cau lenh sed cau hinh dhcp
	#
	# ghi vao file log
	echo "s/iface $1.*/$(getConfigIpStringDebian $1 $2 $3 $4 $5)/" >> $LOG_FILE 
	# cau lenh sed cau hinh static
	sed -i "s/iface $1.*/$(getConfigIpStringDebian $1 $2 $3 $4 $5)/" $NETWORK_CONFIG_DEBIAN
	return 0

}

##################################################
# Ham lay dia chi ip tren may debian
#
getIpInfoDebian(){
	[ $# -eq 0 ] && return 1
	# lay dhcp hay static	
	type=$(sed -n "/iface $1/,/iface/ s/iface $1 inet//p"  $NETWORK_CONFIG_DEBIAN|sed -e 's/^[[:space:]]*//')
	# lenh sed lay dia chi ip
	ip=$(sed -n "/iface $1/,/iface/ s/address//p"  $NETWORK_CONFIG_DEBIAN|sed -e 's/^[[:space:]]*//')
	# lenh sed lay subnetmask
	netmask=$(sed -n "/iface $1/,/iface/ s/netmask//p"  $NETWORK_CONFIG_DEBIAN|sed -e 's/^[[:space:]]*//')
	# lenh sed lay default gateway
	gateway=$(sed -n "/iface $1/,/iface/ s/gateway//p"  $NETWORK_CONFIG_DEBIAN|sed -e 's/^[[:space:]]*//')
	# ghi log file
	echo "config getIpInfoDebian: Type:$type" >> $LOG_FILE
	echo "config getIpInfoDebian: IP:$ip" >> $LOG_FILE
	echo "config getIpInfoDebian: netmask:$netmask" >> $LOG_FILE
	echo "config getIpInfoDebian: gateway:$gateway" >> $LOG_FILE
	# kiem tra ip co ton tai trong file cau hinh
	[ -n "$ip" -a -n "$netmask" ] && { echo "$type:$ip:$netmask:$gateway"; return 0; }
	# lay dia chi ip tu lenh ifconfig
	ipInfo=$(getIfconfigInfo $1)
	# ghi log file
	echo "config getIpInfoDebian: ipInfo:$ipInfo" >> $LOG_FILE
	[ -n "$ipInfo" ] && echo $ipInfo || echo "dhcp:-:-:-"
}

##################################################
# Ham main
#
main(){
	old=$(getIpInfoDebian $3)	
	echo "config getInfoIp: $old" >> $LOG_FILE;
	oldGateway=$(getDefaultGateway)
	[ -n "$oldgateway" ] || oldgateway="-"
	[ "$2" == "-" ] || setDefaultGateway $2
	[ "$4" == "static" -o "$4" == "dhcp" ] && setIpDebian $3 $4 $5 $6 $7 \
	&& echo  $1:$oldGateway:$2:$3:$old:$4:$5:$6:$7\
	|| echo  $1:$oldGateway:$2:$3:$old:-:-:-:-:-
}
echo "**********" $(date -R) >> $LOG_FILE
echo "config value: $1 $2 $3 $4 $5 $6 $7" >> $LOG_FILE
result=$(main $1 $2 $3 $4 $5 $6 $7)
echo $result
echo "config result: $result" >> $LOG_FILE