#!/bin/bash
##################################################
# Name: configuration.sh
# Description: File cau hinh ip va lay dia chi ip tren remote host
#
##################################################
# Set Script Variables
#
# dia chi file cau hinh Debian hoac Ubuntu
NETWORK_CONFIG_DEBIAN="/etc/network/interfaces"
# dia chi file log (luu lai cac buoc cau hinh)
LOG_FILE="settingIpLog.txt"
##################################################
# Ham lay dia chi ip tu lenh ifconfig neu hien tai dang su dung ip dong
#
getIfconfigInfo(){
	# neu khong co ten card mang truyen vao return 1: ham thuc hien khong thanh cong
	#										return 0: ham thuc hien thanh cong
	[ $# -eq 0 ] && return 1
	# cat dia chi ip tu lenh ifconfig 
	local ip=$(ifconfig $1  2> /dev/null|grep "inet addr"|cut -f 2 -d ":"|cut -f 1 -d " ")
	# cat subnetmask tu lenh ifconfig
	local netmask=$(ifconfig $1  2> /dev/null|grep "Mask"|cut -f 4 -d ":")
	# echo ra dia chi ip va netmask neu tim thay
	# echo "" neu khong tim thay
	[ -n "$ip" -a -n "$netmask" ] && echo "dhcp:$ip:$netmask" || echo ""
}
# Ham lay dia chi default gateway
#
getDefaultGateway(){
	# lay dia chi default gateway tu lenh route
	# neu dong nao co flag UG( Up and Gateway) thi bo bot khoang cach lay cot thu 2
	route |grep UG|sed -e 's/[[:space:]]\+/ /g'|cut -f2 -d' '
}

# Ham dat default gateway
#
setDefaultGateway(){
	# return 1 neu khong co gia tri ip truyen vao
	[ $# -eq 0 ] && return 1
	# lay dia chi default gateway hien tai su dung ham getDefaultGateway
	local oldgateway=$(getDefaultGateway)
	# kiem tra neu ton tai default gateway thi xoa cai hien tai
	[ -n "$oldgateway" ] && route del default gw $oldgateway
	# them vao default gateway, neu khong duoc thi tra ve ham thuc hien khong thanh cong
	route add default gw $1|| return 1
}

##################################################
# Ham lay string cau hinh ip, netmask, gateway cho may debian
#
getConfigIpStringDebian(){
	# tao string de gan vao file /etc/network/interfaces
	[ "$2" == "dhcp" ] && printf "iface $1 inet dhcp"'\\n' || printf "iface $1 inet static"'\\n'
	# neu cau hinh static thi them dia chi ip vao
	[ -n "$3" ] && [ "$2" == "static" ] && printf '\\t'"address $3"'\\n'
	[ -n "$4" ] && [ "$2" == "static" ] && printf '\\t'"netmask $4"'\\n'
	# neu chua co vi du: auto eth0 thi them vao
 	grep -q "auto $1" $NETWORK_CONFIG_DEBIAN|| printf "auto $1"'\\n'
}

##################################################
# Ham cau hinh ip cho may debian
#
setIpDebian(){
	# return 1 neu khong co gia tri ip truyen vao
	[ $# -eq 0 ] && return 1
	# Kiem tra neu file cau hinh khong co hoac khonng ton tai interface
	# thi them vao
	[ -f "$NETWORK_CONFIG_DEBIAN" ] && grep -q "iface $1" $NETWORK_CONFIG_DEBIAN || \
	{ echo "iface $1" >> $NETWORK_CONFIG_DEBIAN; echo "config setIpDebian: Config file $1 not found" >> $LOG_FILE; }	
	
	# cau lenh sed xoa tat ca cac dong cau hinh trong interface hien tai
	# vi du
	# iface eth0 inet static
	# 	address 1.1.1.1
	#	255.255.255.0
	# iface eth1 inet dhcp
	# ==>> thanh
	# iface eth0 inet static
	# iface eth1 inet dhcp
	sed -i.bak "/iface $1/,/iface/{//!d}" $NETWORK_CONFIG_DEBIAN
	#
	# ghi vao file log
	echo "s/iface $1.*/$(getConfigIpStringDebian $1 $2 $3 $4 $5)/" >> $LOG_FILE 
	# cau lenh sed thay the interface cau hinh
	sed -i "s/iface $1.*/$(getConfigIpStringDebian $1 $2 $3 $4 $5)/" $NETWORK_CONFIG_DEBIAN
	# khoi dong lai interface (card mang)
	ifdown $1 >> $LOG_FILE
	ifup $1 >> $LOG_FILE
	return 0

}

##################################################
# Ham lay dia chi ip tren may debian
#
getIpInfoDebian(){
	[ $# -eq 0 ] && return 1
	# lay ip dang thiet lap la dhcp hay static	
	type=$(sed -n "/iface $1/,/iface/ s/iface $1 inet//p"  $NETWORK_CONFIG_DEBIAN|sed -e 's/[[:space:]]\+//')
	# lenh sed lay dia chi ip
	local ip=$(sed -n "/iface $1/,/iface/ s/address//p"  $NETWORK_CONFIG_DEBIAN|sed -e 's/[[:space:]]\+//')
	# lenh sed lay subnetmask
	local netmask=$(sed -n "/iface $1/,/iface/ s/netmask//p"  $NETWORK_CONFIG_DEBIAN|sed -e 's/[[:space:]]\+//')
	# ghi log file
	echo "config getIpInfoDebian: Type:$type IP:$ip netmask:$netmask" >> $LOG_FILE
	# kiem tra ip co ton tai trong file cau hinh /etc/network/interfaces
	[ -n "$ip" -a -n "$netmask" ] && { echo "$type:$ip:$netmask"; return 0; }
	# neu khong co ta lay dia chi ip tu lenh ifconfig
	local ipInfo=$(getIfconfigInfo $1)
	# ghi log file
	echo "config getIpInfoDebian: ipInfo:$ipInfo" >> $LOG_FILE
	[ -n "$ipInfo" ] && echo $ipInfo || echo "-:-:-"
}

##################################################
# Ham main
#
main(){
	# lay dia chi ip hien tai
	local old=$(getIpInfoDebian $3)	
	echo "config getInfoIp: $old" >> $LOG_FILE;
	# lay dia chi defaut gateway hien tai
	local oldGW=$(getDefaultGateway)
	# dia chi default gateway moi
	local newGateway=$2
	# echo - neu khong co gateway hien tai
	[ -n "$oldGW" ] || oldGW="-"
	# echo - neu khong dat duoc default gateway 
	# dia chi default gateway can phai ket noi duoc (ping) moi dat thanh cong
	[ "$2" == "-" ] || setDefaultGateway $2 || newGateway="-"
	echo "config oldgateway:$oldGW newGateway:$newGateway" >> $LOG_FILE;
	# dat ip va hien thi thong tin ip hien tai
	[ "$4" == "static" ] && { newIP=$5; newSubnet=$6; } || { newIP="-"; newSubnet="-"; }
	[ "$4" == "static" -o "$4" == "dhcp" ] && setIpDebian $3 $4 $5 $6
	echo  $1:$oldGW:$newGateway:$3:$old:$4:$newIP:$newSubnet
}
echo "**********" $(date -R) >> $LOG_FILE
echo "config value: $1 $2 $3 $4 $5 $6" >> $LOG_FILE
result=$(main $1 $2 $3 $4 $5 $6)
echo $(date +'%kh%Mm%Ss'):$result
echo "config result: $result" >> $LOG_FILE