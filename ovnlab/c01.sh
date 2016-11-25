#!/usr/bin/bash

ovn-nbctl lr-add r1
ovn-nbctl lrp-add r1 r1-sw1 00:00:00:00:01:29 172.16.255.129/26

ovn-nbctl lr-add r2
ovn-nbctl lrp-add r2 r2-sw2 00:00:00:00:01:93 172.16.255.193/26

# both addresses are not pingable from both directions
ovn-nbctl lrp-add r1 r1_r2 00:00:00:01:00:02 172.16.255.2/31 peer=r2_r1
ovn-nbctl lrp-add r2 r2_r1 00:00:00:01:00:03 172.16.255.3/31 peer=r1_r2

ovn-nbctl lr-route-add r1 "172.16.255.192/26" 172.16.255.3
ovn-nbctl lr-route-add r2 "172.16.255.128/26" 172.16.255.2

ovn-nbctl ls-add sw1

ovn-nbctl lsp-add sw1 sw1-r1
ovn-nbctl lsp-set-type sw1-r1 router
ovn-nbctl lsp-set-addresses sw1-r1 00:00:00:00:01:29
ovn-nbctl lsp-set-options sw1-r1 router-port=r1-sw1

ovn-nbctl ls-add sw2

ovn-nbctl lsp-add sw2 sw2-r2
ovn-nbctl lsp-set-type sw2-r2 router
ovn-nbctl lsp-set-addresses sw2-r2 00:00:00:00:01:93
ovn-nbctl lsp-set-options sw2-r2 router-port=r2-sw2

ovn-nbctl lsp-add sw1           sw1-vm1
ovn-nbctl lsp-set-addresses     sw1-vm1 "00:00:00:00:01:31 172.16.255.131"
ovn-nbctl lsp-set-port-security sw1-vm1 "00:00:00:00:01:31 172.16.255.131"

ovn-nbctl lsp-add sw1           sw1-vm2
ovn-nbctl lsp-set-addresses     sw1-vm2 "00:00:00:00:01:32 172.16.255.132"
ovn-nbctl lsp-set-port-security sw1-vm2 "00:00:00:00:01:32 172.16.255.132"

ovn-nbctl lsp-add sw2           sw2-vm3
ovn-nbctl lsp-set-addresses     sw2-vm3 "00:00:00:00:01:95 172.16.255.195"
ovn-nbctl lsp-set-port-security sw2-vm3 "00:00:00:00:01:95 172.16.255.195"

ovn-nbctl lsp-add sw2           sw2-vm4
ovn-nbctl lsp-set-addresses     sw2-vm4 "00:00:00:00:01:96 172.16.255.196"
ovn-nbctl lsp-set-port-security sw2-vm4 "00:00:00:00:01:96 172.16.255.196"

sw1Dhcp="$(ovn-nbctl create DHCP_Options cidr=172.16.255.128/26 \
  options="\"server_id\"=\"172.16.255.129\" \"server_mac\"=\"00:00:00:00:01:29\" \
  \"lease_time\"=\"3600\" \"router\"=\"172.16.255.129\"")"
echo $sw1Dhcp

sw2Dhcp="$(ovn-nbctl create DHCP_Options cidr=172.16.255.192/26 \
  options="\"server_id\"=\"172.16.255.193\" \"server_mac\"=\"00:00:00:00:01:93\" \
  \"lease_time\"=\"3600\" \"router\"=\"172.16.255.193\"")"
echo $sw2Dhcp

ovn-nbctl lsp-set-dhcpv4-options sw1-vm1 $sw1Dhcp
ovn-nbctl lsp-set-dhcpv4-options sw1-vm2 $sw1Dhcp

ovn-nbctl lsp-set-dhcpv4-options sw2-vm3 $sw2Dhcp
ovn-nbctl lsp-set-dhcpv4-options sw2-vm4 $sw2Dhcp

