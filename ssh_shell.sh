#!/usr/bin/expect -f
spawn ssh localhost
expect "login:" 
send "hiep\r"
expect "Password:"
send ";'\r"
interact
