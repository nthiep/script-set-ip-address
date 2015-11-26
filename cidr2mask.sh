cidr2mask() {
  local full_octets=$(($1/8))
  local partial_octet=$(($1%8))
  local i mask=""
  
  for ((i=0;i<4;i+=1)); do
    if [ $i -lt $full_octets ]; then
      mask+=255
    elif [ $i -eq $full_octets ]; then
      mask+=$((256 - 2**(8-$partial_octet)))
    else
      mask+=0
    fi  
    test $i -lt 3 && mask+=.
  done
  echo $mask
}