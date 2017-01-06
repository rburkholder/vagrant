#!/bin/sh

# basic defines
RAW=$1.seed.raw
FIXED=$1.seed.fixed

# pre-checks
if [ ! -f $RAW ]; then
  echo "can not find $RAW (results of debconf-get-selections)"
  exit 1
fi

sed -e 's/.*SSH server$/# SSH server/' \
    -e 's/^d-i[[:space:]]netcfg\/get_ipaddress/#d-i\tnetcfg\/get_ipaddress/' \
    -e 's/^d-i[[:space:]]netcfg\/get_hostname/#d-i\tnetcfg\/get_hostname/' \
    -e 's/^d-i[[:space:]]netcfg\/get_nameservers/#d-i\tnetcfg\/get_nameservers/' \
    $RAW > $FIXED
exit 0
