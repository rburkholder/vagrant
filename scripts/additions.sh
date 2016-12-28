#! /usr/bin/bash

# this script should be copied into /home/vagrant
# used by initial packaging process, and everytime kernel is updated

function cleanup {

  # package clean up
  apt-get -y autoremove
  apt-get -y autoclean
  apt-get -y purge
  apt-get -y clean
      
  # remove indexes
  rm /var/lib/apt/lists/*
      
  # todo: look at /lib/modules when kernel upgraded
  
  # zero out unused space for more efficient packing
  echo "Zeroing out dead space ..."
  dd if=/dev/zero of=/EMPTY bs=1M
  rm -f /EMPTY
  }

function fixsudo {
  cat <<EOT >> /etc/sudoers.d/10-sudo-overrides
Defaults      env_keep += "GIT_*"
Defaults>root env_keep += SSH_AUTH_SOCK
Defaults>root !requiretty
%sudo         ALL=NOPASSWD: ALL
EOT
  }

function installkey {

  # default vagrant key for bootstrapping   
  echo "Installing default key ...."
  if [[ ! -d /home/vagrant/.ssh ]]; then
    mkdir /home/vagrant/.ssh
    chown vagrant.vagrant /home/vagrant/.ssh
    chmod 700 /home/vagrant/.ssh
    fi
  pushd /home/vagrant/.ssh
  wget -q --no-check-certificate \
    'https://raw.github.com/mitchellh/vagrant/master/keys/vagrant.pub' \
    -O authorized_keys
  chmod 600 /home/vagrant/.ssh/authorized_keys
  chown vagrant.vagrant /home/vagrant/.ssh/authorized_keys
  popd
  }

function vagrantuser {
  fixsudo
  installkey
  }

function guestadditions {

  VBOXVER="$1"
  
  # obtain and mount the VBoxGuestAdditions iso
  echo "Obtaining Guest Additions ..."
  wget -q \
    http://download.virtualbox.org/virtualbox/${VBOXVER}/VBoxGuestAdditions_${VBOXVER}.iso 
  mkdir /media/VBoxGuestAdditions
  mount -o loop,ro VBoxGuestAdditions_${VBOXVER}.iso /media/VBoxGuestAdditions
  
  # build the additions
  echo "Building additions ..."
  KERN_DIR=/usr/src/linux-headers-$(uname -r) \
    sh /media/VBoxGuestAdditions/VBoxLinuxAdditions.run
    
  # unmount and remove the iso
  echo "Building done, unmount iso ..."
  umount /media/VBoxGuestAdditions
  rmdir /media/VBoxGuestAdditions
  rm VBoxGuestAdditions_${VBOXVER}.iso 

  }

function build {

  VBOXVER="$1"
  HEADERS="$2"
      
  echo "sources:  "
  cat /etc/apt/sources.list | awk '/^deb/ {print $0}'
  
  # install build tools for the VirtualBox Guest Additions, required for Vagrant
  echo "updating packages ..."
  apt-get update
  echo "installing packages ..."
  PACKAGES=$(apt-get -y install ${HEADERS} build-essential | awk \
'BEGIN { flag=0; list="" } \
/^[^ ]/ { flag=0 } \
/NEW packages will be installed/ { flag=1 } \
/  / { if (1 == flag) list=list$0 } \
END { print list }' \
)
  echo "Installed packages:  ${PACKAGES}"

  guestadditions ${VBOXVER}
          
  # remove packages
  echo "Removing packages and cleaning up ..."
  apt-get -y remove ${PACKAGES}
  apt-get -y remove linux-headers-$(uname -r)

  # add in some commonly used packages
  apt-get -y install less tcpdump vim

  cleanup
      
  # show guest stuff installed
  ls -alt /usr/src
  df -h

  IMAGECNT=$(dpkg -l | grep linux-image | wc -l)
   if  [ "1" != "${IMAGECNT}" ]; then
     echo "More than one image installed, remove excess to reclaim space"
     dpkg -l | grep linux-image
     fi

  uname -a
  }

if [ "root" != $(whoami) ]; then
  echo "need to be user root"
else
  if [ "0" == "$#" ]; then
    echo "commands:"
    echo "  clean:         remove package cruft"
    echo "  key:           install default vagrant key"
    echo "  build VBOXVER: build additions only (custom kernel)"
    echo "  all VBOXVER:   install sudoer, keys, and build (default kernel)"
  else
    case "$1" in
      clean)
        cleanup
        ;;
      key)
        installkey
        ;;
      build)
        # customized headers have been installed
        VBOXVER=$2
        build ${VBOXVER}
        ;;
      all)
        # sudo and ssh key are one time settings
        if [[ "" == "$(ls -d /usr/src/vbox*)" ]]; then
          vagrantuser
          fi
        # distribution standard headers to be installed
        VBOXVER=$2
        build ${VBOXVER} linux-headers-$(uname -r)
        ;;
      *)
        echo "command not available: $1"
        ;;
      esac
    fi
  fi
