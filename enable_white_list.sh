#!/bin/bash
# Modify script as per your setup
# Usage: Sample firewall script
# ---------------------------
_input=/home/pi/wl.db
_user_db_path=${PWD##*//}/
#_pub_if="wlan0"
#IPT=/sbin/iptables

HTTPS=443
HTTP=80
IPRANGE=10.5.5.0/24




function createWLdb() {
        arr=("$@")
        for i in "${arr[@]}";
        do
          echo "$i" >> wl2.db
          echo "$i  - Added"
         sleep 0.2
        done
        sleep 0.5
        echo "File wl2.db created!"
}

function main(){
        local _input_l=$1
#       echo "$_input_l"
        # Die if file not found
        [ -f "_input_l" ] && { echo "$0: File $_input_l not found."; exit 1; }

        ### Setup our white  list ###
        # remove all current rules
        iptables -F

        # Allow all loopback (lo0) traffic and reject traffic
        # to localhost that does not originate from lo0.
        iptables -A INPUT -i lo -j ACCEPT
        iptables -A INPUT ! -i lo -s 127.0.0.0/8 -j REJECT
        # Allow SSH connections.
        iptables -A INPUT -p tcp --dport 22 -m state --state NEW -j ACCEPT

        # Allow HTTP and HTTPS connections from anywhere
        # (the normal ports for web servers).
        iptables -A INPUT -p tcp --dport 80 -m state --state NEW -j ACCEPT
        iptables -A INPUT -p tcp --dport 443 -m state --state NEW -j ACCEPT

        # Allow inbound traffic from established connections.
        # This includes ICMP error returns.
        iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

        # Log what was incoming but denied (optional but useful).
        iptables -A INPUT -m limit --limit 5/min -j LOG --log-prefix "iptables_INPUT_denied: " --log-level 7

        # Reject all other inbound.
        iptables -A INPUT -j REJECT

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

        i=1
        egrep -v "^#|^$"  $_input_l | while IFS= read -r ip
        do
                        echo -e "${GREEN}$i:  $ip --> OK ${RED}"
                        ((i++))
        # Append everything to white list FORWARDING
        # iptables -A FORWARD -p tcp -s $IPRANGE -d $ip --dport $HTTPS -j LOG --log-prefix "WhiteList: FORWARD:"
        #iptables -A FORWARD -p tcp -s $IPRANGE -d $ip --dport $HTTP -j LOG --log-prefix "WhiteList: FORWARD:"
                        iptables -A FORWARD -m limit --limit 5/min -j LOG --log-prefix "iptables_FORWARD_denied: " --log-level 7
                        sleep 0.1
                        iptables -A FORWARD -p tcp -s $IPRANGE -d $ip --dport $HTTPS -j ACCEPT -m comment --comment "$ip"
                        sleep 0.1
                        iptables -A FORWARD -p tcp -s $IPRANGE -d $ip --dport $HTTP -j ACCEPT  -m comment --comment "$ip"
        done
        #<"${_input_l}"
                        iptables -A FORWARD -p tcp  -s $IPRANGE  -m multiport --dports $HTTPS,$HTTP  -m state --state NEW  -j  REJECT
        echo -e "${NC}"
}


while getopts ":a" opt; do
  case $opt in
    a)
      echo "Please enter host or an ip: " >&2
        read _single_host

         echo "1: $_single_host"
                        iptables -F

                        iptables -A FORWARD -p tcp -s $IPRANGE -d $_single_host/24 --dport $HTTPS -j ACCEPT -m comment --comment "$ADDRESS"
                        iptables -A FORWARD -p tcp -s $IPRANGE -d $_single_host/24 --dport $HTTP -j ACCEPT  -m comment --comment "$ADDRESS"
                        iptables -A FORWARD -p tcp  -s $IPRANGE  -m multiport --dports $HTTPS,$HTTP  -m state --state NEW  -j  REJECT

exit 0
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      ;;
  esac
done

echo "<<Configuration>>"
echo -n  "Leave default settings? (y/n) [Enter]:  "
read -n 1 _def
echo
if [[ $_def == n* ]]
then
        echo "Do you have a db of White List sites? (y/n) [Enter] "
        read -n 1 _is_db
        if [[ $_is_db == y* ]]
        then
                echo -n "Enter your White List DB name and press [ENTER] (file should lay in the same folder as script): "
                read  _custom_db
                main $_user_db_path$_custom_db
        else
                echo -n  "Enter White list sites (via spaces), wl2.db file will be created next to current script and press [Enter]: "
                read -a _wl_arr
                createWLdb "${_wl_arr[@]}"
                main $_user_db_path"wl2.db"
        fi
else
        main $_input
fi
