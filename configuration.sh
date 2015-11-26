# config file

NETWORK_CONFIG_DEBIAN="interfaces"
NETWORK_CONFIG_REDHAT="/etc/sysconfig/network-scripts/ifcfg-"
LOG_FILE="settingIpLog.txt"

getIfconfigInfo(){
	[ $# -eq 0 ] && return 1
	ip=$(ifconfig $1  2> /dev/null|grep "inet addr"|cut -f 2 -d ":"|cut -f 1 -d " ")
	netmask=$(ifconfig $1  2> /dev/null|grep "Mask"|cut -f 4 -d ":")
	[ -n "$ip" -a -n "$netmask" ] && echo "$ip:$netmask" || echo ""
}
getIpInfoRedhat(){
	[ $# -eq 0 ] && return 1
	ip=$(sed -n 's/IPADDR=//p'  interfaces|sed -e 's/^[[:space:]]*//')
	netmask=$(sed -n 's/NETMASK=//p'  interfaces|sed -e 's/^[[:space:]]*//')
	[ -n "$ip" -a -n "$netmask" ] && { echo "$ip:$netmask"; return 0; }
	ipInfo=$(getIfconfigInfo $1)
	[ -n "$ipInfo" ] && echo $ipInfo || return 1
}

getConfigIfStringDebian(){
	[ "$2" == "dhcp" ] && printf "iface $1 inet dhcp"'\\n' || printf "iface $1 inet static"'\\n'
	return 0
}
getConfigIpStringDebian(){
	[ -n "$1" ] && printf '\\t'"address $1"'\\n'
	[ -n "$2" ] && printf '\\t'"netmask $2"'\\n'
	[ -n "$3" ] && printf '\\t'"gateway $3"'\\n'
}
setIpDebian(){
	[ -f "$NETWORK_CONFIG_DEBIAN" ] && grep -q "iface $1" $NETWORK_CONFIG_DEBIAN || \
	{ echo "iface $1" >> $NETWORK_CONFIG_DEBIAN; echo "config setIpDebian: Config file $1 not found" >> $LOG_FILE; }	
	sed -i.bak "/iface $1/,/iface/{//!d}" $NETWORK_CONFIG_DEBIAN
	[ "$2" == "dhcp" ] && { sed -i "s/iface $1.*/$(getConfigIfStringDebian $1 $2)/" $NETWORK_CONFIG_DEBIAN; return 0; }
	echo "s/iface $1.*/$(getConfigIfStringDebian $1 $2)$(getConfigIpStringDebian $3 $4 $5)/" >> $LOG_FILE 
	sed -i "s/iface $1.*/$(getConfigIfStringDebian $1 $2)$(getConfigIpStringDebian $3 $4 $5)/" $NETWORK_CONFIG_DEBIAN
	return 0

}
setIpRedhat(){
	[ -f "$NETWORK_CONFIG_REDHAT$1" ] || echo "" > $NETWORK_CONFIG_DEBIAN$1
	[ -n "$2" ] && { grep -q "^BOOTPROTO=" $NETWORK_CONFIG_DEBIAN$1 && sed "s/^BOOTPROTO=.*/BOOTPROTO=$2/" -i $NETWORK_CONFIG_DEBIAN$1 || sed "$ a\BOOTPROTO=$2" -i $NETWORK_CONFIG_DEBIAN$1; }
	[ -n "$3" ] && { grep -q "^IPADDR=" $NETWORK_CONFIG_DEBIAN$1 && sed "s/^IPADDR=.*/IPADDR=$3/" -i $NETWORK_CONFIG_DEBIAN$1 || sed "$ a\IPADDR=$3" -i $NETWORK_CONFIG_DEBIAN$1; }
	[ -n "$4" ] && { grep -q "^NETMASK=" $NETWORK_CONFIG_DEBIAN$1 && sed "s/^NETMASK=.*/NETMASK=$4/" -i $NETWORK_CONFIG_DEBIAN$1 || sed "$ a\NETMASK=$4" -i $NETWORK_CONFIG_DEBIAN$1; }
	[ -n "$5" ] && { grep -q "^GATEWAY=" $NETWORK_CONFIG_DEBIAN$1 && sed "s/^GATEWAY=.*/GATEWAY=$5/" -i $NETWORK_CONFIG_DEBIAN$1 || sed "$ a\GATEWAY=$5" -i $NETWORK_CONFIG_DEBIAN$1; }
	
	grep -q "^FOOBAR=" file && sed "s/^FOOBAR=.*/FOOBAR=newvalue/" -i file || sed "$ a\FOOBAR=newvalue" -i file
}
getIpInfoDebian(){
	[ $# -eq 0 ] && return 1
	ip=$(sed -n "/iface $1/,/iface/ s/address//p"  $NETWORK_CONFIG_DEBIAN|sed -e 's/^[[:space:]]*//')
	netmask=$(sed -n "/iface $1/,/iface/ s/netmask//p"  $NETWORK_CONFIG_DEBIAN|sed -e 's/^[[:space:]]*//')
	echo "config getIpInfoDebian: IP:$ip" >> $LOG_FILE
	echo "config getIpInfoDebian: netmask:$netmask" >> $LOG_FILE
	[ -n "$ip" -a -n "$netmask" ] && { echo "$ip:$netmask"; return 0; }
	ipInfo=$(getIfconfigInfo $1)
	echo "config getIpInfoDebian: ipInfo:$ipInfo" >> $LOG_FILE
	[ -n "$ipInfo" ] && echo $ipInfo || return 1
}
isDebianOS(){
	local VERSION_FILE="/proc/version"
	version=$(cat $VERSION_FILE)
	[[ "$version" == *"ubuntu"* ]] || [[ "$version" == *"debian"* ]] && return 0 || return 1
}
checkCidr(){
	(($1>=0 && $1<=32)) && return 0
	return 1
}
settingIp(){
	result=$(isDebianOS && setIpDebian $1 $2 $3 $4 $5 || setIpRedhat $1 $2 $3 $4 $5)
	echo "config settingIp: $result" >> $LOG_FILE; 
}
getInfoIp(){
	isDebianOS && result=$(getIpInfoDebian $1) || result=$(getIpInfoRedhat $1)
	echo $result
	echo "config getInfoIp: $result" >> $LOG_FILE; 
}
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