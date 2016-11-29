#!/bin/sh
# don't run this in the guest, do this from the hosting computer, in the dnsmasq directory

function createlinks {
  # common files - note that these links make sense only inside the dnsmasq guest
  ln -s /vagrant/over-ride.seed tftp/seeds/over-ride.seed
  ln -s /vagrant/forcestatic.sh tftp/seeds/forcestatic.sh

  ln -s /vagrant/bnbx.stretch.seed       tftp/seeds/bnbx.stretch.seed
  ln -s /vagrant/bnbx.stretch.seed.fixed tftp/seeds/bnbx.stretch.seed.fixed
  
  # device specific links
  ln -s /vagrant/bnbx.manu.boot.pxe tftp/pxelinux.cfg/01-00-90-0b-40-a8-68
  #ln -s /vagrant/bnbx.auto.boot.pxe tftp/pxelinux.cfg/01-00-90-0b-40-a8-68
  
  }

if [[ ! -e netboot.tar.gz ]]; then
  echo 'run one of the following ...'
  echo 'wget --no-check-certificate https://d-i.debian.org/daily-images/amd64/daily/netboot/netboot.tar.gz'
  echo 'curl https://d-i.debian.org/daily-images/amd64/daily/netboot/netboot.tar.gz -o netboot.tar.gz'
else
  if [[ ! -d tftp ]]; then
    mkdir tftp
    fi
  cd tftp
  tar zxvf ../netboot.tar.gz
  if [[ ! -d seeds ]]; then
    mkdir seeds
    fi
  cd .. 
  fi

createlinks

# ----- misc notes

# on the guest:
# apt-get install debconf-utils
# debconf-get-selections --installer > seed.txt
# debconf-get-selections >> seed.txt
# scp seed.txt vagrant@192.168.11.11:/home/vagrant/bnbx.stretch.seed.raw

# then on dnsmasq server:
# mv /home/vagrant/bnbx.stretch.seed.raw /vagrant/
# sed 's/.*SSH server$/# SSH server/' bnbx.stretch.seed.raw > bnbx.stretch.seed.fixed

# a useful command on the guest to run to erase the 
#   operating system, reboot, and have the pxe boot take over
#     ie in boot menu, diskboot followed by pxeboot
# dd if=/dev/zero of=/dev/sda count=1 bs=512
