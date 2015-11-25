# import
. cidr2mask.sh
. mask2cidr.sh
# config file

NETWORK_CONFIG_DEBIAN="/etc/network/interfaces"
NETWORK_CONFIG_REDHAT="/etc/sysconfig/network-scripts/ifcfg-"
RESULT_FILE="result.txt"
DEFAULT_NETMASK="255.255.255.0"
SYSADMIN_USERNAME="sysadmin"

getIpInfoRedhat(){
	[ $# -eq 0 ] && return 1
	ip=sed -n 's/IPADDR=//p'  interfaces|sed -e 's/^[[:space:]]*//'
	netmask=sed -n 's/NETMASK=//p'  interfaces|sed -e 's/^[[:space:]]*//'
	[ -n "$ip" -a -n "$netmask" ] && { echo "$ip:$netmask"; return 0; }
	ipInfo=getIfconfigInfo $1
	[ -n "$ipInfo" ] && echo $ipInfo || return 1
}

getIfconfigInfo(){
	[ $# -eq 0 ] && return 1
	ip=ifconfig $1 |grep "inet addr"|cut -f 2 -d ":"|cut -f 1 -d " "
	netmask=ifconfig $1 |grep "Mask"|cut -f 4 -d ":"
	[ -n "$ip" -a -n "$netmask" ] && echo "$ip:$netmask" || echo ""
}
setIpDebian(){
	[ -f "$NETWORK_CONFIG_DEBIAN" ] && grep -q "iface $1" $NETWORK_CONFIG_DEBIAN || echo getConfigIfStringDebian $1 $2 >> $NETWORK_CONFIG_DEBIAN
	[ "$2" == "dhcp" ] && { sed -i.bak 's/iface $1/$(getConfigIfStringDebian $1 $2)/p' $NETWORK_CONFIG_DEBIAN; return 0; }
	sed -i.bak '/iface $1/,/iface/{//!d}' $NETWORK_CONFIG_DEBIAN
	sed 's/iface $1/$(getConfigIfStringDebian $1 $2)$(getConfigIpStringDebian $3 $4 $5)/p' $NETWORK_CONFIG_DEBIAN 

}
getConfigIfStringDebian(){
	[ "$2" == "dhcp" ] && echo "iface $1 inet dhcp\n" || echo "iface $1 inet static\n"
	return 0
}
getConfigIpStringDebian(){
	[ -n "$1" ] && echo "\taddress $1\n"
	[ -n "$2" ] && echo "\tnetmask $2\n"
	[ -n "$3" ] && echo "\tgateway $3\n"
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
	ip=sed -n '/iface $1/,/iface/ s/address//p'  $NETWORK_CONFIG_DEBIAN|sed -e 's/^[[:space:]]*//'
	netmask=sed -n '/iface $1/,/iface/ s/netmask//p'  $NETWORK_CONFIG_DEBIAN|sed -e 's/^[[:space:]]*//'
	[ -n "$ip" -a -n "$netmask" ] && { echo "$ip:$netmask"; return 0; }
	ipInfo=getIfconfigInfo $1
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
	isDebianOS && setIpDebian $1 $2 $3 $4 $5 || setIpRedhat $1 $2 $3 $4 $5
}
getInfoIp(){
	isDebianOS && getIpInfoDebian $1 || getIpInfoRedhat $1
}
usage(){
	cat README.md
	exit 1
}
main(){
	while IFS=: read host iface status setip setnetmask setgateway
	do
		[ "$status" == "static" -o "$status" == "dhcp" ] &&  settingIp $iface $status $setip $setnetmask $setgateway \
		&& echo  $host:$iface:$(ssh $SYSADMIN_USERNAME@$host getInfoIp $iface) >> $RESULT_FILE \
		|| echo  $host:$iface:$(ssh $SYSADMIN_USERNAME@$host getInfoIp $iface):$status:$setip:$setnetmask:setgateway >> $RESULT_FILE
	done < "$1"
}
[ $# -eq 0 ]  && usage
main $1