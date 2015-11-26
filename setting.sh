
# import
. cidr2mask.sh
. mask2cidr.sh

DEFAULT_NETMASK="255.255.255.0"
SCRIP_FILE="configuration.sh"
SYSADMIN_USERNAME="hiep"
RESULT_FILE="result.txt"
main(){
	while IFS=: read host iface status setip setnetmask setgateway
	do
		echo "setting file " $host $iface $status $setip $setnetmask $setgateway
		result=$(ssh $SYSADMIN_USERNAME@$host 'bash -s' < $SCRIP_FILE $host $iface $status $setip $setnetmask $setgateway)
		echo $result >> $RESULT_FILE
	done < "$1"
}

usage(){
	cat README.md
	exit 0
}
[ $# -eq 0 ]  && usage
main $1