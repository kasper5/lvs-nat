#!/bin/bash

### BEGIN INIT INFO

# Provides:          ipforward-daemon
# Required-Start:    $network $local_fs $remote_fs
# Required-Stop:     $network $local_fs $remote_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Enable IP forwarding. 
# Description:   	 Bash script that will enable IP forwarding,
# and configure the firewall (iptables) with NAT. 

# Start Date : 2015-09-22
# End Date : 2015-09-22
# Author : Kasper Fast
# Version : 0.1    

### END INIT INFO

# set -e 
# set -x

if [ "$( id -u )" -ne 0 ]; then printf "Please run script as root!\n"; exit 0; fi; 

. /lib/lsb/init-functions

# System configuration file
SYS=/etc/sysctl.conf
PROC=/proc/sys/net/ipv4/ip_forward
IPTABLES=$( which iptables )
SED=$( which sed )
GREP=$( which grep )
CAT=$( which cat )
AWK=$( which awk )
ECHO=$( which echo )

if [ -z "$IPTABLES" ]; then printf "ERROR: can't find iptables binaries!\n"; exit 0; fi;

# This function will find the ip forward parameter in /etc/sysctl.conf file and uncomment it
# and it'll enable ip forward. 
enable_ipforward(){

		# Enable ip forwarding
		"$ECHO" 1 > "$PROC"; 

		# This will find the line number where the ip forwarding parameter is. This number will be used with sed. 
		LINE_NUM=$( "$CAT" -n $SYS | "$GREP" -E "net.ipv4.ip_forward=./?" | "$AWK" '{print $1}' )

		# Uncomment the line. 
		"$SED" -i "$LINE_NUM s/^#//" "$SYS";

}

disable_ipforward(){

		# disable ip forwarding
		"$ECHO" 0 > "$PROC";

		LINE_NUM=$( "$CAT" -n $SYS | "$GREP" -E "net.ipv4.ip_forward=./?" | "$AWK" '{print $1}' )

		# Comment back the line
		"$SED" -i "$LINE_NUM s/^/#/" "$SYS";

}

flush_iptables(){

		"$IPTABLES" -F;
		"$IPTABLES" -Z;
		"$IPTABLES" -t nat -F;
}

create_iptables(){

		flush_iptables;
		"$IPTABLES" -t nat -A POSTROUTING -o eth0 -j MASQUERADE;
		"$IPTABLES" -A FORWARD -i eth0 -o eth1 -m state --state RELATED,ESTABLISHED -j ACCEPT;
		"$IPTABLES" -A FORWARD -i eth1 -o eth0 -j ACCEPT;
}

if [ $# -lt 1 ]
then
		printf "USAGE: %s {start|stop} \n" "$0";
		exit 0;
fi

case "$1" in
	
	start )
		enable_ipforward;
		create_iptables;
		;;

	stop )
		disable_ipforward;
		flush_iptables;
		;;
esac
