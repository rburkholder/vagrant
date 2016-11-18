#! /usr/bin/bash

function build {

  KRNLVER=$1

  # remove a file so it doesn't block the installation process
  if [[ -e /etc/kernel-img.conf ]]; then
    mv /etc/kernel-img.conf /etc/kernel-img.conf.backup
    fi
  
  # Install packages required for building the kernel, and creating a Debian compatible package:
  apt-get update
  apt-get -y install build-essential fakeroot rsync git
  apt-get -y install bc libssl-dev dpkg-dev libncurses5-dev
  apt-get -y install kernel-package dirmngr
  apt-get -y build-dep linux
  
  NAME=linux-${KRNLVER}.tar

  if [[ ! -e ${NAME} ]]; then
    if [[ -e /vagrant/${NAME}.xz ]]; then
      cp /vagrant/${NAME}.xz .
    else
      wget -q --no-check-certificate https://cdn.kernel.org/pub/linux/kernel/v4.x/${NAME}.xz
      fi
    if [[ ! -d ${NAME} ]]; then
      unxz ${NAME}.xz
      fi
    fi
      
  if [[ ! -e ${NAME}.sign ]]; then
    if [[ -e /vagrant/${NAME}.sign ]]; then
      cp /vagrant/${NAME}.sign .
    else
      wget -q --no-check-certificate https://cdn.kernel.org/pub/linux/kernel/v4.x/${NAME}.sign
      fi
    fi
  
  # Confirm authenticity of the source:
  gpg --keyserver hkp://keys.gnupg.net --recv-keys 38DBBDC86092693E
  gpg --verify ${NAME}.sign ${NAME}
  
  # Untar the source:
  if [[ ! -d linux-${KRNLVER} ]]; then
    tar xf ${NAME}
    fi
  
  # Copy over an existing Debian configuration file:
  cd linux-${KRNLVER}
  cp /boot/config-$(uname -r) .config
  
  # remove trusted key setting
  sed -i 's/CONFIG_SYSTEM_TRUSTED_KEYS=.*/CONFIG_SYSTEM_TRUSTED_KEYS=""/' .config

  # update config for new kernel
  # A new default .config could be generated with 'make defconfig'.
  yes "" | make oldconfig
  # make olddefconfig
  scripts/config --disable DEBUG_INFO
  # possible issue with as of Kernel 4.4
  # scripts/config --disable CC_STACKPROTECTOR_STRONG
   
  # examine the KEYS 
  grep CONFIG_SYSTEM_TRUSTED_KEYRING  .config
  grep CONFIG_MODULE_SIG_KEY .config
  grep CONFIG_SYSTEM_TRUSTED_KEYS .config
  
  # update package maintainer values  
  # sudo cp /etc/kernel-pkg.conf.dpkg-new /etc/kernel-pkg.conf
  sed -i 's/^maintainer.*/maintainer := Raymond Burkholder/' /etc/kernel-pkg.conf
  sed -i 's/^email.*/email := raymond@burkholder.net/' /etc/kernel-pkg.conf
  
  # https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=841420
  # http://unix.stackexchange.com/questions/319761/cannot-compile-kernel-error-kernel-does-not-support-pic-mode/319830
  if [[ "0" == "$(grep -c 'fno-pie' Makefile)" ]]; then
    sed -i '/^all: vmlinux/a \
KBUILD_CFLAGS += $(call cc-option, -fno-pie) \
KBUILD_CFLAGS += $(call cc-option, -no-pie) \
KBUILD_AFLAGS += $(call cc-option, -fno-pie) \
KBUILD_CPPFLAGS += $(call cc-option, -fno-pie)' Makefile
    fi

  # perform build
  make clean
  rm -rf debian
  time make-kpkg --rootcmd fakeroot --initrd --revision=1.0 \
    --append-to-version=-custom kernel_image kernel_headers -j $(grep processor /proc/cpuinfo | wc -l)
	
  if [[ -d /vagrant_packages ]]; then
    mv ../linux-headers-${KRNLVER}-custom_1.0_amd64.deb /vagrant_packages/
    mv ../linux-image-${KRNLVER}-custom_1.0_amd64.deb /vagrant_packages/
    fi
  }

if [[ "" == "$1" ]]; then
  echo "need kernel version to build (like 4.8.8)"
else 
  echo "building kernel version $1 ..."
  build $1  
  fi

