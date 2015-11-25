sed -i.bak '/iface eth0/,/iface/{//!d}' interfaces 
sed  's/iface eth0/iface\n\tsdfsd\n\tsdfsd\n/p'  interfaces 
sed -n '/iface eth0/,/iface/ s/address//p'  interfaces|sed -e 's/^[[:space:]]*//'
grep -q "^FOOBAR=" file && sed "s/^FOOBAR=.*/FOOBAR=newvalue/" -i file || sed "$ a\FOOBAR=newvalue" -i file


usage(){
	cat README.md
}
checkCidr(){
	(($1>=0 && $1<=32)) && return 0
	return 1
}