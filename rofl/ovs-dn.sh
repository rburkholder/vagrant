ovs-vsctl del-controller sw1

ovs-vsctl --if-exists del-port veth1n
ip link del dev veth1n

ovs-vsctl --if-exists del-port veth2n
ip link del dev veth2n



ip netns del ns2
ip netns del ns1

ovs-vsctl --if-exists del-br sw1
