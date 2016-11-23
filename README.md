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
* bldkrnlpkg is used to build a new kernel from kernel.org
```
KRNLVER=4.8.10 vagrant up --provision-with bldkernel
```

### VirtualBox Additions
* additions is used to install a new kernel and update the VirtualBox additions
* once completed, make a new package
```
KRNLVER=4.8.10 VBOXVER=5.1.8 vagrant up --provision-with newkernel
KRNLVER=4.8.10 VBOXVER=5.1.8 SYNC_DISABLED=true vagrant reload --provision-with newadditions
KRNLVER=4.8.10 VBOXVER=5.1.8 vagrant reload --provision-with fixkey
# perform packaging step, then...
KRNLVER=4.8.10 VBOXVER=5.1.8 vagrant destroy -f
```

### Build Openvswitch packages
* bldovs is used to build openvswitch and ovn packages
```
 KRNLVER=4.8.10 OVSVER=2.6.1 vagrant up
```

### Spool up OVN environment for testing
* ovnlab makes use of the new kernel and ovs packages to run test environments
```
 KRNLVER=4.8.10 OVSVER=2.6.1 vagrant up
```
