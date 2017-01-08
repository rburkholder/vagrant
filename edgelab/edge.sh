ovs-vsctl add-br br0 \
	  -- set bridge br0 fail-mode=secure \
	  -- set-controller br0 tcp:127.0.0.1 \
          -- set bridge br0 protocols=OpenFlow14 

ovs-vsctl add-port br0 enp0s9
ovs-vsctl add-port br0 enp0s10
ovs-vsctl add-port br0 enp0s16

ovs-vsctl add-port br-int vm1 -- set interface vm1 type=internal
ip link set vm1 address 00:00:00:00:01:31
ip link set up dev vm1
#ovs-vsctl set Interface vm1 external_ids:iface-id=sw1-vm1

