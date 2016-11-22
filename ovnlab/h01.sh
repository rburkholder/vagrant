ENCAP_INTERFACE=enp0s9
ip link set dev ${ENCAP_INTERFACE} mtu 9000

ovs-vsctl add-br br-int -- set Bridge br-int fail-mode=secure

ovs-vsctl set open . external-ids:ovn-remote=tcp:10.10.101.2:6642
ovs-vsctl set open . external-ids:ovn-encap-type=geneve
ovs-vsctl set open . external-ids:ovn-encap-ip=10.10.104.2

# ---
ovs-vsctl add-port br-int vm1 -- set interface vm1 type=internal
ip link set vm1 address 00:00:00:00:01:31
ip link set up dev vm1
ovs-vsctl set Interface vm1 external_ids:iface-id=sw1-vm1

ip netns add vm1
ip netns exec vm1 ip link set dev lo up
ip link set vm1 netns vm1
ip netns exec vm1 dhclient vm1
ip netns exec vm1 ip addr show vm1
ip netns exec vm1 ip route show

#---
ovs-vsctl add-port br-int vm3 -- set Interface vm3 type=internal
ip link set vm3 address 00:00:00:00:01:95
ip link set up dev vm3
ovs-vsctl set Interface vm3 external_ids:iface-id=sw2-vm3

ip netns add vm3
ip netns exec vm3 ip link set dev lo up
ip link set vm3 netns vm3
ip netns exec vm3 dhclient vm3
ip netns exec vm3 ip addr show vm3
ip netns exec vm3 ip route show
