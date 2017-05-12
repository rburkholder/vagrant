
ip link set dev ovs-system up

ovs-vsctl --may-exist add-br sw1
ip link set dev sw1 up
#ovs-vsctl set bridge sw1 
ovs-vsctl set bridge sw1 protocols=OpenFlow13
ovs-vsctl set-fail-mode sw1 secure
ovs-vsctl set-controller sw1 tcp:127.0.0.1:6653


ip netns add ns1
ip link add veth1n type veth peer name veth1f
ip link set up dev veth1n
ip link set veth1f netns ns1
ip netns exec ns1 ip addr add dev veth1f 10.0.0.1/24
ip netns exec ns1 ip link set dev veth1f up
#ovs-vsctl --may-exist add-port sw1 veth1n -- set Interface veth1n type=internal
ovs-vsctl --may-exist add-port sw1 veth1n tag=10

ip netns add ns2
ip link add veth2n type veth peer name veth2f
ip link set up dev veth2n
ip link set veth2f netns ns2
ip netns exec ns2 ip addr add dev veth2f 10.0.0.2/24
ip netns exec ns2 ip link set dev veth2f up
#ovs-vsctl --may-exist add-port sw1 veth2n -- set Interface veth2n type=internal
ovs-vsctl --may-exist add-port sw1 veth2n tag=10

ip netns exec ns1 ping 10.0.0.2

ip netns list
ip link list

ovs-vsctl list-ports
ovs-vsctl list-ifaces


