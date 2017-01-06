#!/bin/sh

# basic defines
RAW=$1.seed.raw
FIXED=$1.seed.fixed

# pre-checks
if [ ! -f $RAW ]; then
  echo "can not find $RAW (results of debconf-get-selections)"
  exit 1
fi

sed    's/.*SSH server$/# SSH server/' $RAW > $FIXED
sed -i 's/^d-i\tnetcfg\/get_ipaddress/#d-i\tnetcfg\/get_ipaddress/' $FIXED
sed -i 's/^d-i\tnetcfg\/get_hostname/#d-i\tnetcfg\/get_hostname/' $FIXED
sed -i 's/^d-i\tnetcfg\/get_nameservers/#d-i\tnetcfg\/get_nameservers/' $FIXED
exit 0
