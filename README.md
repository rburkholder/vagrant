# Utilities for building kernels, guest additions, ovs/ovn testing
# (based upon Debian Stretch/Testing)

## Basic outline:

### Bootstrap the project:
* need to bootstrap the project with a manual build of a minimal Debian Stretch image:
 * for VirtualBox settings:, 
   * call it 'stretch' in the gui, 
   * with 512M memory, 10G drive, 
   * use virtio driver for network, use NAT as the network type
   * disable floppy and audio
 * I typically use a weekly or daily snapshot iso from https://www.debian.org/devel/debian-installer/
 * while building, some things to do: 
   * use expert mode to install, 
   * use targeted drivers (which keeps the image smaller),
   * don't allow root login, use 'vagrant' as the install user (which installs sudo, which is used by vagrant)
   * for partitioning: create 100m /boot on ext3 (don't use ext4 as it may complain of a missing crc32c module on some rebuilds), remainder on / with btrfs (no swap)
   * deselect all packages, enable only the ssh server package, 
* once the build is complete, and the guest has rebooted:
 * create a port forward in the network->advanced settings, from 2002 to 22 for the guest  (just put in the two port numbers, no ip addresses required)
 * from the host: 
```
scp -P 2002 scripts/additions.sh vagrant@127.0.0.1:/home/vagrant/
```
 * ssh into the guest: 
```
ssh -p 2002 vagrant@127.0.0.1
```
 * check what version of VirtualBox you have (has to be >= 5.1.8), and use that version number in the guest: 
```
sudo bash additions.sh all 5.1.10
```
 * where 5.1.10 is the version of VirtualBox installed
 * then shutdown the image:
```
sudo shutdown -h now
```
* back on the host, run 
```
bash scripts/pack.sh stretch stretch-4.8.7
```
  * the first 'stretch' is the source VirtualBox image name, while 'stretch-4.8.7' is the destination Vagrant box package name, with the version of kernel it has

### pprx - Package Proxy / Caching
* use the pprx to build and start a apt-cacher-ng based package proxy (helps make further local builds faster)
* it has two interfaces:  an internal one and an external, allowing it to be used by virtual as well as physical clients
```
KRNLVER=4.8.7 vagrant up
```
* this guest needs to be running for the subsequent guests

### bldkrnlpkg - Building a kernel
* bldkrnlpkg - is used to build a new kernel from kernel.org (requires 8 to 10 GB harddrive). OLDKRNLVER is assigned with whatever native kernel you built in the initial boostrap step.  NEWKRNLVER is whatever kernel you would like to build from kernel org.  Currently, a three digit version is required, so rc versions and 4.xx versions might pose a problem.
```
OLDKRNLVER=4.8.7 NEWKRNLVER=4.8.12 vagrant up
```
To optionally (re)build another kernel using the same image:
```
OLDKRNLVER=4.8.7 NEWKRNLVER=4.8.12 vagrant up --provision-with bldkernel
```

### additions - VirtualBox Additions
* additions - used to install a new kernel and update the VirtualBox additions
* once completed, make a new package
```
KRNLVERBASE=4.8.7 KRNLVERBLD=4.8.12 VBOXVER=5.1.10 vagrant up --provision-with newkernel
KRNLVERBASE=4.8.7 KRNLVERBLD=4.8.12 VBOXVER=5.1.10 vagrant halt
KRNLVERBASE=4.8.7 KRNLVERBLD=4.8.12 VBOXVER=5.1.10 SYNC_DISABLED=true vagrant up --provision-with newadditions
```
* you may see a message like:
```
==> default: More than one image installed, remove excess to reclaim space
==> default: ii  linux-image-4.8.0-1-amd64     4.8.7-1                     amd64        Linux 4.8 for 64-bit PCs (signed)
==> default: ii  linux-image-4.8.12-custom     1.0                         amd64        Linux kernel binary image for version 4.8.12-custom
```
* ssh in and:
```
sudo apt remove linux-image-4.8.0-1-amd64
sudo bash additions.sh clean
sudo shutdown -h now
```
* fix up the key, which auto-halts afterwards
```
KRNLVERBASE=4.8.7 KRNLVERBLD=4.8.12 VBOXVER=5.1.10 vagrant up --provision-with fixkey
```
* perform packaging step (substituting correct kernel version):
```
pushd ..
bash scripts/pack.sh stretch-4.8.12-additions stretch-4.8.12
popd
```
* then...
```
KRNLVERBASE=4.8.7 KRNLVERBLD=4.8.12 VBOXVER=5.1.10 vagrant destroy -f
```

### bldovs - Build Openvswitch packages
* bldovs - is used to build openvswitch and ovn packages
```
 KRNLVER=4.8.10 vagrant up
```

### ovnlab - Spool up OVN environment for testing
* ovnlab - makes use of the new kernel and ovs packages to run test environments
```
 KRNLVER=4.8.10 OVSVER=2.7.90 vagrant up
```
### dnsmasq - DNSMASQ Used to install Linux on Lanner Box
* requires env KRNLVER: kernel version to use from packaged boxes
* requires env ACTIVEINT: interface in dnsmasq box for physical interface to connect to Lanner box (maybe enp0s9)
* Lanner box needs to be set for PXE boot mode (driveboot, followed by pxeboot)
* before starting up dnsmasq guest, run the following to setup an initial environment:
```
bash setup.sh
```
* then startup the dnsmasq guest, and ssh into it
```
KRNLVER=4.8.10 ACTIVEINT=enp0s9 vagrant up
KRNLVER=4.8.10 ACTIVEINT=enp0s9 vagrant ssh
```
* in the guest:
```
tail -f /var/log/daemon.log' and watch for mac address
```
* start the Lanner box, watch the daemon.log, and given the mac address, need to add two lines to /etc/dnsmasq.d/local like (mac address, ip address, box name, and mask):
```
dhcp-host=00:90:0b:40:a8:68,set:host_192.168.11.5,192.168.11.5,bnbx001,3600
dhcp-option=tag:host_192.168.11.5,option:netmask,255.255.255.0
```
* restart the service:
```
systemctl restart dnsmasq
```
* Also run the following to create a manual install ability (to obtain debian seed file, substitute the correct mac address):
```
ln -s /vagrant/pxe/bnbx.manu.boot.pxe tftp/pxelinux.cfg/01-00-90-0b-40-a8-68
```
* perform the install and use root (don't add a normal user), 
   otherwise in the later auto-install phase, 
     the user's password will be requested (distrupting the auto install process)
* after the reboot, log in to the Lanner box as root, and obtain the seed file:
```
# install package
apt-get install debconf-utils
# collect seed file
debconf-get-selections --installer > seed.txt
debconf-get-selections >> seed.txt
# copy seed file to dnsmasq server
scp seed.txt vagrant@192.168.11.11:/vagrant/seeds/bnbx.stretch.seed.raw
# zero out boot sector so will restart to rebuild automatically
dd if=/dev/zero of=/dev/sda bs=512 count=1
# shutdown
shutdown -h now
```
* on host, run:
```
bash scripts/fix-seed.sh seeds/bnbx.stretch
# on mac: bash scripts/fix-seed.mac.sh seeds/bnbx.stretch
rm tftp/pxelinux.cfg/01-00-90-0b-40-a8-68
ln -s /vagrant/pxe/bnbx.auto.boot.pxe tftp/pxelinux.cfg/01-00-90-0b-40-a8-68
```
* turn the power on for the Lanner box, and it should boot and perform an auto-install
* setup.sh and Vagrantfile should be updated with the new 'ln -s ....' setting for that mac address
