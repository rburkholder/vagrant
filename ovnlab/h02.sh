#!/usr/bin/bash

if [[ "1" != "$#" ]]; then
  echo "need the encap interface name"
else

  ENCAP_INTERFACE=$1
  bash /vagrant/encap.sh ${ENCAP_INTERFACE}
  IPV4=$(ip -h -f inet -br addr show dev ${ENCAP_INTERFACE} | awk 'BEGIN {FS=" "} {print $3}' | cut -d'/' -f1)
  if [[ "" == "${IPV4}" ]]; then
    echo "no interface?  no ip address?  aborted"
  else

    ovs-vsctl add-br br-int -- set Bridge br-int fail-mode=secure
    
    ovs-vsctl set open . external-ids:ovn-remote=tcp:10.10.102.2:6642
    ovs-vsctl set open . external-ids:ovn-encap-type=geneve
    ovs-vsctl set open . external-ids:ovn-encap-ip=${IPV4}
    
    #---
    ovs-vsctl add-port br-int vm2 -- set interface vm2 type=internal
    ip link set vm2 address 00:00:00:00:01:32
    ip link set up dev vm2
    ovs-vsctl set Interface vm2 external_ids:iface-id=sw1-vm2
    
    ip netns add vm2
    ip netns exec vm2 ip link set dev lo up
    ip link set vm2 netns vm2
    ip netns exec vm2 dhclient vm2
    ip netns exec vm2 ip addr show vm2
    ip netns exec vm2 ip route show
    
    # ---
    ovs-vsctl add-port br-int vm4 -- set Interface vm4 type=internal
    ip link set vm4 address 00:00:00:00:01:96
    ip link set up dev vm4
    ovs-vsctl set Interface vm4 external_ids:iface-id=sw2-vm4
    
    ip netns add vm4
    ip netns exec vm4 ip link set dev lo up
    ip link set vm4 netns vm4
    ip netns exec vm4 dhclient vm4
    ip netns exec vm4 ip addr show vm4
    ip netns exec vm4 ip route show

    fi

  fi
