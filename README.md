## Shell script setting ip and gateway ##
-------
usage 
<!-- highlight:-d language:console -->
	./configuration {filename} (setting_file.txt)
-------
setting file format
<!-- highlight:-d language:console -->
	ipaddress:[DefaultGateway]:[interface:[type]:[setip]:[setnetmask]

	DiaChiHost:[DefaultGateway]:[Cardmang:[static/dhcp]:[diachiIP]:[Subnetmask]

result file format
<!-- highlight:-d language:console -->
	ipaddress:OldGateway:NewGateway:interface:oldtype:oldip:oldnetmask:newtype:newip:newnetmask
#### HOA - TUAN - HIEP ####
