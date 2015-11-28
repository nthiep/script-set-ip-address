#!/bin/bash
##################################################
# Name: setting.sh
# Description: main setting file
# Kich ban:
# - co file cau hinh gom danh sach may va cac thuoc tinh
# - DiaChiHost:[DefaultGateway]:[Cardmang:[static/dhcp]:[diachiIP]:[Subnetmask]]
# - de dat default gateway
# - DiaChiHost:DefaultGateway
# ket qua file
# ipaddress:OldGateway:NewGateway:interface:oldtype:oldip:oldnetmask:newtype:newip:newnetmask
##################################################
# Set Script Variables
#
SCRIP_FILE="configuration.sh"
SYSADMIN_USERNAME="root"
RESULT_FILE="result.txt"
LOG_FILE="settingIpLog.txt"
SSH_ERROR="Not_connect"
##################################################
# Gan dia chi ip tu dong neu khong co 
# neu trong file cau hinh dia chi may khong dat ip thi tu dong tang ip cua may truoc do
# vi du: may1: 192.168.0.1 --> may2 ip la 192.168.0.2
getAutoIp(){
	local IFS=.
	set -- $*
	[ $# -eq 4 ] || return 1
	[ $4 -lt 254 ] && { echo $1.$2.$3.$(($4+1)); return 0; }	
	[ $3 -lt 254 ] && { echo $1.$2.$(($3+1)).1; return 0; }
	[ $2 -lt 254 ] && { echo $1.$(($2+1)).0.1; return 0; }	
	[ $1 -lt 254 ] && { echo $(($1+1)).0.0.1; return 0; } || return 1
}
##################################################
# Ham kiem tra dia chi ip, neu dia chi ip khong hop le se dat dia chi ip tu dong ham getAutoIp
#
isValidip(){
	case "$*" in
	""|*[!0-9.]*|*[!0-9]) return 1 ;;
	esac

	local IFS=.
	set -- $*

	[ $# -eq 4 ] &&
	[ ${1:-666} -le 255 ] && [ ${2:-666} -le 255 ] &&
	[ ${3:-666} -le 255 ] && [ ${4:-666} -le 254 ]
}

##################################################
# Chuong trinh chinh
# Doc lan luoc danh sach cac may va cac cau hinh phan cach nhau boi dau :
# DiaChiHost:[DefaultGateway]:[Cardmang:[static/dhcp]:[diachiIP]:[Subnetmask]
# [] co the co hoac khong
#
main(){
	# ham while doc vao cac bien phan cach boi dau :
	while IFS=: read thisHost thisDefaultGateway thisIface thisType thisSetip thisSetnetmask
	do
		echo "******** Setting ip for host $thisHost:$thisIface **********"
		echo "read file " $thisHost $thisDefaultGateway $thisIface $thisType $thisSetip $thisSetnetmask
		# kiem tra dia chi ip hoac hostname
		[ -n "$thisHost" ] && host=$thisHost || continue
		# kiem tra default gateway
		[ -n "$thisDefaultGateway" ] && isValidip $thisDefaultGateway && defaultGateway=$thisDefaultGateway \
		|| [ -n "$defaultGateway" ] || defaultGateway="-"
		# kiem tra interface
		[ -n "$thisIface" ] && iface=$thisIface
		# trang thai la static hay dhcp hay null
		[ -n "$thisType" ] && type=$thisType
		# kiem tra dia chi ip
		[ -n "$thisSetip" ] && isValidip $thisSetip && setip=$thisSetip || setip=$(getAutoIp $setip) 
		# kiem tra subnetmask
		[ -n "$thisSetnetmask" ] && setnetmask=$thisSetnetmask
		###########
		echo "setting file " $host $defaultGateway $iface $type $setip $setnetmask $setgateway
		# chay script cau hinh va lay dia chi ip subnetmask tren remote host
		ssh $SYSADMIN_USERNAME@$host 'bash -s' < $SCRIP_FILE $host $defaultGateway $iface $type $setip $setnetmask \
		>> $RESULT_FILE || echo $(date +'%kh%Mm%Ss'):$host:$SSH_ERROR >> $RESULT_FILE
		# doc file log va xoa
		# < /dev/null hoac ssh -n: dung chuyen huong stdin cua ssh vao /dev/null
		ssh $SYSADMIN_USERNAME@$host "cat $LOG_FILE ; rm $LOG_FILE" < /dev/null >> $LOG_FILE 
	done < "$1"
	# $1 ten file cau hinh: ./setting setting_file.txt
	# $1 = setting_file.txt
}

usage(){
	cat README.md
	exit 0
}
[ $# -eq 0 ]  && usage
main $1
