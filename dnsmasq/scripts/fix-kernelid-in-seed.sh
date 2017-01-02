#export OLDVER=4.2.0-1
#export NEWVER=4.3.0-1
export OLDVER=4.4.0-1
export NEWVER=4.5.0-1
#export OLDVER=4.4.0-1
#export NEWVER=4.3.0-1
export SEEDFILE=/etc/qvsl/salt/dnsmasq/seeds/bnbx.stretch.seed
#export SEEDFILE=salt/dnsmasq/seeds/bnbx.stretch.seed
#export SEEDFILE=bnbx.stretch.seed
#export SEEDFILE=bnbx.stretch.seed
grep linux-image $SEEDFILE
sed -i "s/linux-image-$OLDVER/linux-image-$NEWVER/g" $SEEDFILE
sed -i "s/depmod-error-initrd-$OLDVER/depmod-error-initrd-$NEWVER/g" $SEEDFILE
sed -i "s/mips-initrd-$OLDVER/mips-initrd-$NEWVER/g" $SEEDFILE
sed -i "s/removing-running-kernel-$OLDVER/removing-running-kernel-$NEWVER/g" $SEEDFILE
grep linux-image $SEEDFILE
