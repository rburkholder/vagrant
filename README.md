# vagrant
utilities for building kernels, guest additions, ovs/ovn testing (based upon Debian Stretch/Testing)

Basic outline:

* build a minimal Debian Stretch image, and call it 'stretch' in the gui
* from this archive, scp the scripts/additions.sh file into the image and 'bash additions.sh all 5.1.8' where 5.1.8 is the version of VirtualBox installed (has to be >=5.1.8)
* shutdown the image
* run 'bash scripts/pack.sh stretch stretch', the first 'stretch' is the source VirtualBox image name, the second 'stretch' is the destination Vagrant box package name

* use the pprx to build and start a apt-cacher-ng based package proxy (helps make further local builds faster)
* once started, check the ip address, and update /etc/apt/sources.list in the original stretch image to make a url like:  http://192.168.1.120:3142/ftp.debian.org/debian
* run 'bash scripts/pack.sh stretch stretch' again to make an updated package 
* should run 'vagrant box remove stretch' so that the new package is used in subsequent builds

* bldkrnlpkg is used to build a new kernel from kernel.org

* additions is used to install a new kernel and update the VirtualBox additions
* once completed, make a new package

* bldovs is used to build openvswitch and ovn packages

* ovnlab makes use of the new kernel and ovs packages to run test environments
