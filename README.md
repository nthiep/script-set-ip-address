# Shell script setting ip and gateway #
-------
usage 
<!-- highlight:-d language:console -->
	./configuration {filename}
-------
setting file format
<!-- highlight:-d language:console -->
	ipaddress:[DefaultGateway]:[interface:[type]:[setip]:[setnetmask]:[setgateway]]

	DiaChiHost:[DefaultGateway]:[Cardmang:[static/dhcp]:[diachiIP]:[Subnetmask]:[Gateway]]

result file format
<!-- highlight:-d language:console -->
	ipaddress:OldGateway:NewGateway:interface:oldtype:oldip:oldnetmask:oldgateway:newtype:newip:newnetmask:newgateway
#### HOA - TUAN - HIEP ####
