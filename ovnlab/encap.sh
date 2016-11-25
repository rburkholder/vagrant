if [[ "0" == "$#" ]]; then
  echo "need encap interface name"
else
	if  (( "2" <= "$#" )); then
    echo "only one parameter allowed for encap"
  else 
    ENCAP_INTERFACE=$1
    ip link set dev ${ENCAP_INTERFACE} mtu 9000
    echo "set ${ENCAP_INTERFACE} to 9000 mtu"
    fi
  fi
