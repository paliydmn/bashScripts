#!/bin/bash
if [ "$EUID" -ne 0 ]
  then echo "Please run as root!"
  exit
fi
EMAIL="<paliydmn@digitaldevices.de>"	#e-mail address send the license file to
L_NAME="fsm_lic_upgrade" #default export license name. If <-n> is empty or not used
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
NC='\033[0m' # No Color
#Check Args
if [[ $# -eq 0 ]]; then
        echo -e "No arguments passed. Default valuses applyed:"
        echo -e "command <licese_export>"
        echo -e "license_export file name  = fsm_lic_for_upgrade*.lic"
else
    POSITIONAL_ARGS=()
    while [[ $# -gt 0 ]]; do
		case $1 in
		-e|--lic_export)
			L_EXPORT=1
			shift # past argument
			;;
		-i|--lic_import)
			L_IMPORT=1
            shift # past argument
            ;;
        -n|--name)
			if [[ ! -z $2 ]]; then
				L_NAME="$2"
			fi
			shift # past argument
			shift # past value
			;;
		-h|--help)
			HELP=1
			echo -e "Export/Import license script for FSM card"
			echo -e "-e|--lic_export \n\t Export license for upgrade [never use with <-i option>]"
			echo -e "-i|--lic_import \n\t Import upgraded license. Required <-n> option [never use with <-e option>]"
			echo -e "-n|--name <name> \n\t Enter License name"
			exit
			;;
        esac
	done
set -- "${POSITIONAL_ARGS[@]}" # restore positional parameters
#
fi
cd /tmp
if [ ! -f "ddtest.tar.gz" ]; then 
	wget http://linuxsupport.digital-devices.eu/ddtest.tar.gz
	tar -xvf ddtest.tar*
else
	echo -e "Found FSM card: "
	for i in $(seq $(ls /dev/ddbridge | wc -l));
	do
		n=$(expr $i - 1)
		PCI_SLOT_NAME=`cat /sys/class/ddbridge/ddbridge$n/device/uevent | grep 'PCI_SLOT_NAME' | cut -d '=' -f 2`
		DEVICE_NAME=`dmesg | grep  -i $PCI_SLOT_NAME | grep -i 'Digital Devices\|device name' | cut -d ':' -f 4`
		DEVICE_FW=`dmesg | grep  -i $PCI_SLOT_NAME | grep -i 'FW' | cut -d ':' -f 4`
			## Echo block
	   if [[ $DEVICE_NAME == *"FSM"* ]]; then
			echo -e "\x1B[01;93m Device Number:\t$n \x1B[0m"
			echo -e "\x1B[01;93m DEVICE NAME:\t$DEVICE_NAME \x1B[0m"
			if [[ $L_EXPORT == 1 ]]; then
				echo -e "lic_export "
				./ddtest -d $n licexport $L_NAME
				echo -e "$GREEN Please, send the license file: "
				echo -e "/tmp/$(ls $L_NAME*.lic)"
				echo -e " to E-mail: $EMAIL for the upgrade $NC"
			fi
			if [[ $L_IMPORT == 1 ]]; then
				echo -e "$GREEN lic_import $NC"
				L_NAME=$(ls $L_NAME*)
				IMPORT_RES=$(./ddtest -d $n licimport $L_NAME*)
				if [[ $IMPORT_RES == *"License file not found"* ]]; then 
					echo -e "$RED ERROR: "
					echo -e "$IMPORT_RES"
					echo -e "Please, indicate FSM license file name for importing $NC"
				else
					echo -e "$GREEN Done $NC"
					echo -e "$YELLOW Please, reboot the OS to apply the new FSM license! $NC"
				fi
			fi
	   fi
	done
fi
