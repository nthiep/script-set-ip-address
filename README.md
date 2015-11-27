# Shell script setting ip and gateway #
-------
usage 
<!-- highlight:-d language:console -->
	./configuration {filename}
-------
setting file format
<!-- highlight:-d language:console -->
	ipaddress:interface:[type]:[setip]:[setnetmask]:[setgateway]

	DiaChiHost:Cardmang:[static/dhcp]:[diachiIP]:[Subnetmask]:[Gateway]

result file format
<!-- highlight:-d language:console -->
	ipaddress:interface:[oldtype]:[oldip]:[oldnetmask]:[oldgateway]:[newtype]:[newip]:[newnetmask]:[newgateway]
#### HOA - TUAN - HIEP ####
