#!/bin/bash

# Check if tuner limit exist
STR=`dmesg | grep -o "DVB_MAX_ADAPTERS"`
SUB='DVB_MAX_ADAPTERS'

if [[ "$STR" =~ "$SUB" ]]; then
        echo -e "\033[33;5;7m+-------------------------------------------------+\033[0m"
        echo -e "\033[33;5;7m+   Warning! 8 tuners LIMIT detected.         +\033[0m"
        echo -e "\033[33;5;7m+-------------------------------------------------+\033[0m"
fi
# end check

for i in $(seq $(ls /dev/ddbridge | wc -l)); 
do
    n=$(expr $i - 1)
    echo -e "\x1B[01;93m Device Number: $n \x1B[0m"
    PCI_SLOT_NAME=`cat /sys/class/ddbridge/ddbridge$n/device/uevent | grep 'PCI_SLOT_NAME' | cut -d '=' -f 2`
    echo "PCI: `lspci | grep Multimedia | grep $(echo $PCI_SLOT_NAME | cut -c 6-)`"
    echo "PCI_SLOT_NAME: $PCI_SLOT_NAME"
    dmesg | grep  -i $PCI_SLOT_NAME | grep -i 'device name'
    dmesg | grep  -i $PCI_SLOT_NAME | grep -i 'FW'
	if [[ "$*" == *"-v"* ]]; then
		dmesg -t |grep $PCI_SLOT_NAME | grep TAB
		dmesg -t |grep $PCI_SLOT_NAME | grep "DVB: registering"
	fi
    for t in $(cat /sys/class/ddbridge/ddbridge$n/temp*); 
	do
        rex='^[0-9]+$'
        if  [[ $t =~ $rex ]] ; then
		    DEVICE_TEMP=`echo $t | rev | cut -c 4- | rev`
            echo "T: $DEVICE_TEMP C"
        fi
    done
    echo "-------------------------------------------------"
done
echo "-------------------------------------------------"
#
#
echo -e "ddbridge.conf:\t`cat /etc/modprobe.d/ddbridge.conf`"
echo -e "extra.conf:\t`cat /etc/depmod.d/extra.conf`"
echo -e "-------------------------------------------------"
echo -e "modinfo ddbridge:\t\t`modinfo ddbridge | grep 'version\|filename'`"
#
# start HW/OS details
if [[ "$*" == *"-v"* ]]; then
	. /etc/os-release
	echo -e "\nDistribution:\t$ID $VERSION_ID"
	echo -e "Linux Kernel:\t$(uname -r)"
	echo -e "Architecture:\t$HOSTTYPE ($(getconf LONG_BIT)-bit)"
	TIME_ZONE=$(timedatectl 2>/dev/null | grep -i 'time zone:\|timezone:' | sed -n 's/^.*: //p')
	echo -e "Time zone:\t$TIME_ZONE"
	echo -e "Language:\t$LANG"

	if command -v systemd-detect-virt >/dev/null && CONTAINER=$(systemd-detect-virt -c); then
			echo -e "Virtualization container:\t$CONTAINER"
	fi

	if command -v systemd-detect-virt >/dev/null && VM=$(systemd-detect-virt -v); then
			echo -e "Virtual Machine hypervisor:$VM"
	fi

	echo -e "Bash Version:\t$BASH_VERSION"
	if [[ "$*" == *"-vv"* ]]; then
		echo -e "\nAdapters:"
		echo "$(ls -v /dev/dvb/adapter*)"
	fi
fi
# end HW/OS details
#
#
#echo "$(lspci | grep Multimedia)"
