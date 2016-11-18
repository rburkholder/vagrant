#! /usr/bin/bash

# $1 - source base name
# $2 - packaged box name

if [ 2 != $# ]; then
  echo "two arguments:  VirtualBoxVMName PackagedBoxName"
else 

  VIRTUALBOXNAME=$1
  PACKAGEDNAME=$2

  # create a basic description file
  cat <<EOT >> ${PACKAGEDNAME}.vf
Vagrant::Config.run do |config|
  config.ssh.username = "vagrant"
end
EOT

  # package up the vm
  vagrant package --base ${VIRTUALBOXNAME} --vagrantfile ${PACKAGEDNAME}.vf
  # we'll put the packages vm in a boxes sub-directory
  if [[ ! -d boxes ]]; then
    mkdir boxes
    fi
  # remove a previous cached box
  if [[ -e boxes/${GUESTNAME}.box ]]; then
    vagrant box remove ${PACKAGEDNAME} -f
    rm boxes/${PACKAGEDNAME}.box
    fi
  # put the packaged vm in our sub-directory
  mv package.box boxes/${PACKAGEDNAME}.box
  rm ${PACKAGEDNAME}.vf
  
  echo "use 'vagrant box remove ${PACKAGEDNAME}' to remove existing cached box"

  fi
