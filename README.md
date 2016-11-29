# Utilities for building kernels, guest additions, ovs/ovn testing
# (based upon Debian Stretch/Testing)

## Basic outline:

### Bootstrap the project:
* need to bootstrap the project with a manual build of a minimal Debian Stretch image, and call it 'stretch' in the gui
* from this archive, scp the scripts/additions.sh file into the image and 'bash additions.sh all 5.1.8' where 5.1.8 is the version of VirtualBox installed (has to be >=5.1.8)
* shutdown the image
* run 'bash scripts/pack.sh stretch stretch', the first 'stretch' is the source VirtualBox image name, the second 'stretch' is the destination Vagrant box package name

### Package Proxy / Caching
* use the pprx to build and start a apt-cacher-ng based package proxy (helps make further local builds faster)
* once started, check the ip address, and update /etc/apt/sources.list in the original stretch image to make a url like:  http://192.168.1.120:3142/ftp.debian.org/debian
* run 'bash scripts/pack.sh stretch stretch' again to make an updated package 
* should run 'vagrant box remove stretch' so that the new package is used in subsequent builds
```
vagrant up
```

### Building a kernel
* bldkrnlpkg - is used to build a new kernel from kernel.org
```
KRNLVER=4.8.10 vagrant up --provision-with bldkernel
```

### VirtualBox Additions
* additions - used to install a new kernel and update the VirtualBox additions
* once completed, make a new package
```
KRNLVER=4.8.10 VBOXVER=5.1.8 vagrant up --provision-with newkernel
KRNLVER=4.8.10 VBOXVER=5.1.8 SYNC_DISABLED=true vagrant reload --provision-with newadditions
KRNLVER=4.8.10 VBOXVER=5.1.8 vagrant reload --provision-with fixkey
# perform packaging step, then...
KRNLVER=4.8.10 VBOXVER=5.1.8 vagrant destroy -f
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
* requires env ACTIVEINT: interface on Lanner box used for pxe boot, typically enp1s0
* Lanner box needs to be set for PXE boot mode
* run the following in dnsmasq to setup an initial environment:
```
sudo bash /vagrant/setup.sh
```
* during first boot, 'tail -f /var/log/daemon.log' and watch for mac address
* need to add two lines like (mac address, ip address, box name, and mask)
```
dhcp-host=00:90:0b:40:a8:68,set:host_192.168.11.5,192.168.11.5,bnbx001,3600
dhcp-option=tag:host_192.168.11.5,option:netmask,255.255.255.0
```
* Also run the following to create a manual install ability (to obtain debian seed file):
```
ln -s /vagrant/bnbx.manu.boot.pxe tftp/pxelinux.cfg/01-00-90-0b-40-a8-68
```
* perform the install and use root (don't add a normal user), otherwise in the later auto-install phase, the user's password will be requested (distrupting the auto install process)
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
* on dnsmasq server, run:
```
sed 's/.*SSH server$/# SSH server/' bnbx.stretch.seed.raw > bnbx.stretch.seed.fixed
rm tftp/pxelinux.cfg/01-00-90-0b-40-a8-68
ln -s /vagrant/bnbx.auto.boot.pxe tftp/pxelinux.cfg/01-00-90-0b-40-a8-68
```
* turn the power on for the Lanner box, and it should boot and perform an auto-install
* setup.sh and Vagrantfile should be updated with the new 'ln -s ....' setting for that mac address
