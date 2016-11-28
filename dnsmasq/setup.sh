#!/bin/sh
mkdir tftp
cd tftp
wget http://d-i.debian.org/daily-images/amd64/daily/netboot/netboot.tar.gz
tar zxvf netboot.tar.gz
mkdir seeds
cd .. 

# common files
ln -s /vagrant/over-ride.seed tftp/seeds/over-ride.seed
ln -s /vagrant/forcestatic.sh tftp/seeds/forcestatic.sh

ln -s /vagrant/bnbx.manu.boot.pxe tftp/pxelinux.cfg/01-00-90-0b-40-a8-68

#ln -s /etc/qvsl/bnbx.stretch.seed /var/local/tftp/seeds/bnbx.stretch.seed
#ln -s /etc/qvsl/stretch.seed /var/local/tftp/seeds/stretch.seed

# apt-get install debconf-utils
# debconf-get-selections --installer > seed.txt
# debconf-get-selections >> seed.txt
# scp seed.txt vagrant@192.168.11.11:/home/vagrant/bnbx.stretch.seed.raw

# sed 's/.*SSH server$/# SSH server/' bnbx.stretch.seed.raw > bnbx.stretch.seed.fixed

ln -s /vagrant/bnbx.stretch.seed       tftp/seeds/bnbx.stretch.seed
ln -s /vagrant/bnbx.stretch.seed.fixed tftp/seeds/bnbx.stretch.seed.fixed
