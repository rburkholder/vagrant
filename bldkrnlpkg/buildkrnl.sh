#! /usr/bin/bash

function InstallPackages {

  # Install packages required for building the kernel, and creating a Debian compatible package:
  echo "updating package manager ..."
  sudo apt-get update
  echo "installing packages ..."
  sudo apt-get -y --no-install-recommends \
    install \
      build-essential fakeroot rsync git \
      bc libssl-dev dpkg-dev libncurses5-dev \
      kernel-package dirmngr
  echo "build-dep ..."
  sudo apt-get -y build-dep linux
  
  }

function build {

  KRNLVER=$1

  # remove a file so it doesn't block the installation process
  if [[ -e /etc/kernel-img.conf ]]; then
    sudo mv /etc/kernel-img.conf /etc/kernel-img.conf.backup
    fi
  
  InstallPackages
  
  NAME=linux-${KRNLVER}.tar
  echo "working with ${NAME} ..."
  
  echo "obtaining kernel ..."
  if [[ ! -e ${NAME} ]]; then
    if [[ -e /vagrant/${NAME}.xz ]]; then
      echo "copying existing kernel ..."
      cp /vagrant/${NAME}.xz .
    else
      echo "downloading kernel ... "
      wget -q --no-check-certificate https://cdn.kernel.org/pub/linux/kernel/v4.x/${NAME}.xz
      fi
    if [[ ! -d ${NAME} ]]; then
      echo "expanding kernel ... "
      unxz ${NAME}.xz
      echo "expanding done."
      fi
    fi
      
  echo "perform sign test ..."
  if [[ ! -e ${NAME}.sign ]]; then
    if [[ -e /vagrant/${NAME}.sign ]]; then
      echo "cp sign"
      cp /vagrant/${NAME}.sign .
    else
      echo "obtain sign"
      wget -q --no-check-certificate https://cdn.kernel.org/pub/linux/kernel/v4.x/${NAME}.sign
      echo "done"
      fi
    fi
  
  echo "key test ..."
  # Confirm authenticity of the source:
  #   keyserver requires special port, so may not work without special firewall rule
  gpg --keyserver hkp://keys.gnupg.net --recv-keys 38DBBDC86092693E
  gpg --verify ${NAME}.sign ${NAME}
  
  # Untar the source:
  if [[ ! -d linux-${KRNLVER} ]]; then
    echo "expanding sources ..."
    tar xf ${NAME}
    fi
  
  # Copy over an existing Debian configuration file:
  echo "config file ..."
  cd linux-${KRNLVER}
  cp /boot/config-$(uname -r) .config
  
  # remove trusted key setting
  # sed -i 's/CONFIG_SYSTEM_TRUSTED_KEYS=.*/CONFIG_SYSTEM_TRUSTED_KEYS=""/' .config
  scripts/config --disable CONFIG_SYSTEM_TRUSTED_KEYS

  # update config for new kernel
  # A new default .config could be generated with 'make defconfig'.
  #yes "" | make oldconfig
  make olddefconfig
  # make menuconfig
  scripts/config --disable DEBUG_INFO
  # possible issue with as of Kernel 4.4
  # scripts/config --disable CC_STACKPROTECTOR_STRONG
   
  # examine the KEYS 
  grep CONFIG_SYSTEM_TRUSTED_KEYRING  .config
  grep CONFIG_MODULE_SIG_KEY .config
  grep CONFIG_SYSTEM_TRUSTED_KEYS .config
  
  echo "maintainer ..."
  # update package maintainer values  
  # sudo cp /etc/kernel-pkg.conf.dpkg-new /etc/kernel-pkg.conf
  sudo sed -i 's/^maintainer.*/maintainer := Raymond Burkholder/' /etc/kernel-pkg.conf
  sudo sed -i 's/^email.*/email := raymond@burkholder.net/' /etc/kernel-pkg.conf
  
  # https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=841420
  # http://unix.stackexchange.com/questions/319761/cannot-compile-kernel-error-kernel-does-not-support-pic-mode/319830
#  if [[ "0" == "$(grep -c 'fno-pie' Makefile)" ]]; then
#    sed -i '/^all: vmlinux/a \
#KBUILD_CFLAGS += $(call cc-option, -fno-pie) \
#KBUILD_CFLAGS += $(call cc-option, -no-pie) \
#KBUILD_AFLAGS += $(call cc-option, -fno-pie) \
#KBUILD_CPPFLAGS += $(call cc-option, -fno-pie)' Makefile
#    fi

  SUFFIX="custom"  

  # perform build
  echo "build ...."
  make clean
  rm -rf debian
  # https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=841368
  #-j $(grep processor /proc/cpuinfo | wc -l) 
  # https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=842845 (on latest parallel builds)
  #  KCPPFLAGS="-fno-PIE" 
  #  KCFLAGS="-fno-PIC -fno-PIE" 
  #    -j${CPUCNT} 
  #  KBUILD_VERBOSE=1 
#  time \
#    CPUCNT=$(grep ^processor /proc/cpuinfo|wc -l) \
#    MAKEFLAGS="CC=gcc-6 HOSTCC=gcc-6" \
#    CONCURRENCY_LEVEL=${CPUCNT} \
#    DEB_BUILD_OPTIONS="parallel=${CPUCNT}" \
#    make-kpkg \
#      --rootcmd fakeroot \
#      --revision=1 --append-to-version=-${SUFFIX} \
#      --initrd kernel_image kernel_headers

  # http://www.linuxquestions.org/questions/debian-26/vanilla-kernel-cannot-stat-%91reporting-bugs%92-no-such-file-or-directory-4175601088/
  # www.linuxquestions.org/questions/debian-26/kernel-versaion-4-1-and-4-2-upgrade-compile-guide-4175552272/
  # https://lists.debian.org/debian-kernel/2016/04/msg00575.html    bindeb-pkg
  # https://debian-handbook.info/browse/stable/sect.kernel-compilation.html 
  # EXTRAVERSION="-custom-amd64 KDEB_PKGVERSION=$(make kernelversion)-$(date +%Y%m%d).0 \
  # doesn't seem to solve the parallel build problem
#    KCPPFLAGS="-fno-PIE" KCFLAGS="-fno-PIC -fno-PIE" \
#    DEB_BUILD_OPTIONS="parallel=${CPUCNT}" \
#    CONCURRENCY_LEVEL=${CPUCNT} \
#DEB_BUILD_OPTIONS="parallel=${CPUCNT}"
#CONCURRENCY_LEVEL=${CPUCNT}

CPUCNT=$(grep ^processor /proc/cpuinfo|wc -l)
  time \
    make -j${CPUCNT} \
      deb-pkg LOCALVERSION=-custom KDEB_PKGVERSION=$(make kernelversion)-1

  echo "move to directory ..."
  if [[ -d /vagrant_packages ]]; then
    mv ../linux-headers-${KRNLVER}-${SUFFIX}_${KRNLVER}-1_amd64.deb /vagrant_packages/linux-headers-${KRNLVER}-${SUFFIX}-1_amd64.deb
    mv ../linux-image-${KRNLVER}-${SUFFIX}_${KRNLVER}-1_amd64.deb /vagrant_packages/linux-image-${KRNLVER}-${SUFFIX}-1_amd64.deb
    mv ../linux-firmware-image-${KRNLVER}-${SUFFIX}_${KRNLVER}-1_amd64.deb /vagrant_packages/linux-firmware-image-${KRNLVER}-${SUFFIX}-1_amd64.deb
    mv ../linux-libc-dev_${KRNLVER}-1_amd64.deb /vagrant_packages/linux-libc-dev_${KRNLVER}-${SUFFIX}-1_amd64.deb
    fi
  }

if [[ "" == "$1" ]]; then
  echo "need kernel version to build (like 4.8.8)"
else 
  echo "building kernel version $1 ..."
  build $1  
  fi

