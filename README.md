# Utilities for building kernels, guest additions, ovs/ovn testing
# (based upon Debian Stretch/Testing)

## Basic outline:

### Bootstrap the project:
* need to bootstrap the project with a manual build of a minimal Debian Stretch image:
 * in VirtualBox, call it 'stretch' in the gui, with 512M memory, 10G drive, virtio driver for network, disable floppy and audio
 * I typically use a weekly or daily snapshot iso from https://www.debian.org/devel/debian-installer/
 * while building, some things to do:  use vagrant as the install user; deselect all packages, enable the ssh server package, 
* once the build is complete, and the guest has rebooted:
 * create a port forward from 2002 to 22 for the guest (with a NAT network interface) (just put in the two port numbers, no ip addresses required)
 * from the host: 
```
scp -P 2002 scripts/additions.sh vagrant@127.0.0.1:/home/vagrant/
```
 * ssh into the guest: 
```
ssh -p 2002 vagrant@localhost
```
 * in the guest: 
```
sudo bash additions.sh all 5.1.10
```
 * where 5.1.10 is the version of VirtualBox installed (has to be >=5.1.8)
 * shutdown the image
* in the host, run 
```
bash scripts/pack.sh stretch stretch-4.8.7
```
  * the first 'stretch' is the source VirtualBox image name, while 'stretch-4.8.7' is the destination Vagrant box package name, with the version of kernel it has

### Package Proxy / Caching
* use the pprx to build and start a apt-cacher-ng based package proxy (helps make further local builds faster)
* it has two interfaces:  an internal one and an external, allowing it to be used by virtual as well as physical clients
```
KRNLVER-4.8.7 vagrant up
```
* this guest needs to be running for the subsequent guests

### Building a kernel
* bldkrnlpkg - is used to build a new kernel from kernel.org
```
OLDKRNLVER=4.8.7 NEWKRNLVER=4.8.12 vagrant up --provision-with bldkernel
```

### VirtualBox Additions
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
```
* fix up the key, which auto-halts afterwards
```
KRNLVERBASE=4.8.7 KRNLVERBLD=4.8.12 VBOXVER=5.1.10 vagrant reload --provision-with fixkey
```
* perform packaging step, then...
```
KRNLVERBASE=4.8.7 KRNLVERBLD=4.8.12 VBOXVER=5.1.10 vagrant destroy -f
```

### Build Openvswitch packages
* bldovs - is used to build openvswitch and ovn packages
```
 KRNLVER=4.8.10 OVSVER=2.6.1 vagrant up
```

### Spool up OVN environment for testing
* ovnlab - makes use of the new kernel and ovs packages to run test environments
```
 KRNLVER=4.8.10 OVSVER=2.6.1 vagrant up
```
### DNSMASQ Used to install Linux on Lanner Box
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
ln -s /vagrant/bnbx.manu.boot.pxe tftp/pxelinux.cfg/01-00-90-0b-40-a8-68
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
scp seed.txt vagrant@192.168.11.11:/vagrant/bnbx.stretch.seed.raw
# zero out boot sector so will restart to rebuild automatically
dd if=/dev/zero of=/dev/sda bs=512 count=1
# shutdown
shutdown -h now
```
* on host, run:
```
sed 's/.*SSH server$/# SSH server/' bnbx.stretch.seed.raw > bnbx.stretch.seed.fixed
rm tftp/pxelinux.cfg/01-00-90-0b-40-a8-68
ln -s /vagrant/bnbx.auto.boot.pxe tftp/pxelinux.cfg/01-00-90-0b-40-a8-68
```
* turn the power on for the Lanner box, and it should boot and perform an auto-install
* setup.sh and Vagrantfile should be updated with the new 'ln -s ....' setting for that mac address
