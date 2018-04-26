#!/bin/sh
#
# bootstrap.sh
#
# This script is executed at the end of each multiuser runlevel.
# Make sure that the script will "exit 0" on success or any other
# value on error.
#
# By default this script does something for GYT seat applications.

/opt/gpio_set.sh &
# Enable TouchScreen
/usr/bin/eGTouchD

# Disable a serial of services
/etc/init.d/sshd stop
/etc/init.d/ntpd stop

# Restart network in case it doesn't work
ifdown -a
ifup -a

# run vsftpd
/opt/pre_vsftpd.sh
vsftpd &

# run Seat.out
echo "1" >  /proc/sys/net/netfilter/nf_conntrack_udp_timeout
echo "1" > /proc/sys/net/ipv4/conf/eth0/arp_ignore
iptables -t mangle -A PREROUTING -i eth0 -d 192.168.3.0/24 -j DROP
chmod -R 777 /usr/seat/ata0a
nohup /usr/seat/ata0a/bin/Seat_Linux >/dev/null 2>&1 &
#service vsftpd start

# run seat_imx
/home/root/seat_imx/seat_boot.sh

# run adt_aec
if [ -f /opt/aec/adt_aec.log ]
then rm /opt/aec/adt_aec.log
fi
/opt/aec/start.sh

# unlock gyt_box
if [ -f /home/root/.lock_gyt_box ]
then rm /home/root/.lock_gyt_box
fi

# backlight dimming
echo 20 > /sys/class/backlight/backlight.28/brightness

exit 0
