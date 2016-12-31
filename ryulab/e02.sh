ovs-vsctl add-br br0 \
  -- set bridge br0 fail-mode=secure \
  -- set-controller br0 tcp:10.10.106.2
ovs-vsctl set bridge br0 protocols=OpenFlow14

ovs-vsctl add-port br0 enp0s9
ovs-vsctl add-port br0 enp0s10
ovs-vsctl add-port br0 enp0s16
