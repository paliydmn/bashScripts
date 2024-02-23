#!/bin/bash
##
##Script revision: 0.0.16
REV="0.0.16"
##
# Check root
if [ "$EUID" -ne 0 ]
  then echo "Please run as root!"
  exit
fi
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
NC='\033[0m' # No Color
#Check Args
if [[ $# -eq 0 ]]; then
	echo -e "$GREEN No arguments passed. Default valuses applyed:
		fmode = 0
		dddvb version = 0.9.39
		msi = 1 (enabled) $NC"
	FMODE=0
	VERSION=39
else
	POSITIONAL_ARGS=()
	while [[ $# -gt 0 ]]; do
		case $1 in
		-v|--version)
		  VERSION="$2"
			#If version is not indicated, set latest release 0.9.39 version
		    if [[ $VERSION == ""  ]]; then 
				VERSION=39 
		    fi
			if [[ $VERSION -gt 39 || $VERSION -lt 37 ]]; then
				echo -e "$RED Wrong version value: $VERSION. Possible values: 37, 38, 39. See help (-h|--help) $NC"
				exit
			fi
		  shift # past argument
		  shift # past value
		  ;;
		-f|--fmode)
		  FMODE="$2"
		  if [[ $FMODE -gt 3 || $FMODE -lt 0 || $FMODE == "" ]]; then
			echo -e "$RED FMODE=$FMODE is not correct. See help (-h|--help) $NC"
			exit
		  fi
		  shift # past argument
		  shift # past value
		  ;;
		-g|--git)
		  GIT=1
		  shift # past argument
		  #shift # past value
		  ;;
		-h|--help)
		  HELP=1
		  echo -e "Script version $REV"
		  echo -e "dddvb_build script [OPTIONS] \n"
		  echo -e "-f|--fmode \n\t Set FMODE (default with fmode 0)\n\t Possible values: 0,1,2,3"
		  echo -e "\t Modes for Max S8/SX8/SX8 Basic:
			fmode=0
			\t 4 tuner mode ( Internal multiswitch disabled )
			fmode=1
			\t Quad LNB / normal outputs of multiswitches
			fmode=2
			\t Quattro - LNB / cascade outputs of multiswitches
			fmode=3
			\t Unicable LNB or JESS / Unicabel output of the multiswitch"
		  echo -e "-v|--version \n\t dddvb version to build \n\t Possible values: 37, 38, 39:
			37 is dddvb-0.9.37 
			38 is dddvb-0.9.38
			39 is dddvb-0.9.39"
		  echo -e "-g|--git \n\t ignire -v option and build dddvb latest git version\n"
		  echo -e "-m|--max-adapters \n\t Set MAX ADAPTERS \n\t Possible values: 1,2"
		  echo -e "\t Max Adapters (Default value for dddvb 0.9.38/39 is 64):
			-m 1 = MAX ADAPTERS 128 (set 128 adapters)
			-m 2 = MAX ADAPTERS 256 (set 256 adapters)\n"
		  echo -e "-M|--msi \n\t If you have I²C-Timeouts, please disable MSI for ddbridge \n\t Possible values: 0-disable, 1-enable (default)"
		  echo -e "-h|--help \n\t print this help. Ignore all other options/values\n"
		  exit
		  ;;
		-m|--max-adapters)
		  MAX_A="$2"
		  #possible values 1 = 128 adapters; 2 = 256 adapters;
		  if [[ $MAX_A == 1 ]]; then 
			MAX_A=128
		  elif [[ $MAX_A == 2 ]]; then
			MAX_A=256
		  else
			echo -e "$RED MAX_ADAPTERS=$MAX_A is not correct. See help (-h|--help) $NC"
			exit
		  fi
		##
		  #if [[ $MAX_A -gt 2 || $MAX_A -lt 1 || $MAX_A == "" ]]; then
#
#		  fi
		  shift # past argument
		  shift # past value
		  ;;
		-M|--msi)
		  MSI="$2"
		  #msi: Control MSI interrupts: 0-disable, 1-enable (default) (int)
		  if [[ $MSI == "" || $MSI == 1 ]]; then 
			MSI=1;
		  elif [[ $MSI == 0 ]]; then 
			MSI=0;
		  else
			echo -e "$RED MSI=$MSI is not correct. See help (-h|--help) $NC"
			exit
		  fi
		  echo -e "MSI = $MSI"
		  shift # past argument
		  shift # past value
		  ;;
		-*|--*)
		  echo "$RED Unknown option $1 $NC"
		  exit 1
		  ;;
		*)
		  POSITIONAL_ARGS+=("$1") # save positional arg
		  shift # past argument
		  ;;
		esac
	done
#
	set -- "${POSITIONAL_ARGS[@]}" # restore positional parameters
#
fi
echo 'Prepare system'
if [ -n "`which apt-get`" ]; then apt-get -y install build-essential patchutils libproc-processtable-perl linux-headers-$(uname -r) git;
systemctl disable apt-daily.service
systemctl disable apt-daily.timer ;
elif [ -n "`which yum`" ]; then yum -y group install "Development Tools";
yum -y install perl-CPAN "kernel-devel-uname-r == $(uname -r)" kernel-headers wget perl-core elfutils-libelf-devel;
(echo y;echo o conf prerequisites_policy follow;echo o conf commit)|cpan;
cpan Proc::ProcessTable;
cpan Digest::SHA;
fi
##
cd /usr/src
SUFFIX=$(date +%Y.%m.%d.%H.%M.%S)
#MAX ADAPTERS option, if not indicated, set = 64
if [[ $MAX_A == "" ]]; then 
	MAX_A=64;
fi
#
if [[ $GIT == 1 ]]; then
	if [[ ! -z $VERSION ]]; then
		echo -e "$YELLOW Version value is ignored. See help (-h|--help) $NC\n"
	fi
	echo "Git is selected"
    echo -e "$GREEN Download Latest Git Version: $NC"
    if [ -d "/usr/src/dddvb-git" ]; then
		mv /usr/src/dddvb-git /usr/src/dddvb-git.back.$SUFFIX
    fi
    git clone https://github.com/DigitalDevices/dddvb.git dddvb-git
    cd dddvb-git
    sed -i '/$(MAKE) -C app/s/^/# /' Makefile
	#MAX Adapters limitation is not appyed for version > 0.9.37
	DVB_DEV_PWD=$(find . -name 'dvbdev.h')
	sed -i -e "s/^#if defined(CONFIG_DVB_MAX_ADAPTERS).*$/#if 0/g" $DVB_DEV_PWD
	sed -i -e "s/DVB_MAX_ADAPTERS 64/DVB_MAX_ADAPTERS $MAX_A/g" $DVB_DEV_PWD
elif [[ $VERSION == 37 || $VERSION == 38 || $VERSION == 39 ]]; then
	echo -e "$GREEN Download Release version: 0.9.$VERSION $NC"
    if [ -f "/usr/src/0.9.$VERSION.tar.gz" ]; then
		mv /usr/src/0.9.$VERSION.tar.gz /usr/src/0.9.$VERSION.tar.gz.back.$SUFFIX
    fi
    wget https://github.com/DigitalDevices/dddvb/archive/0.9.$VERSION.tar.gz
    if [ -d "/usr/src/dddvb-0.9.$VERSION" ]; then
		mv /usr/src/dddvb-0.9.$VERSION /usr/src/dddvb-0.9.$VERSION.back.$SUFFIX
    fi
	tar -xf 0.9.$VERSION.tar.gz
    cd dddvb-0.9.$VERSION
#Do not build /app 	folder	
	sed -i '/$(MAKE) -C app/s/^/# /' Makefile
	#MAX Adapters limitation is not appyed for version > 0.9.37
	DVB_DEV_PWD=$(find . -name 'dvbdev.h')
	sed -i -e "s/^#if defined(CONFIG_DVB_MAX_ADAPTERS).*$/#if 0/g" $DVB_DEV_PWD
	sed -i -e "s/DVB_MAX_ADAPTERS 64/DVB_MAX_ADAPTERS $MAX_A/g" $DVB_DEV_PWD
	#			
fi
make clean
#Skip warnings, catch only Errors
ERR_MAKE=$(make 3>&1 >&2 2>&3 3>&- | grep -v "warning" | grep  "error*" )
ERR_MAKE_INST=$(make install 3>&1 >&2 2>&3 3>&- | grep -v "warning" | grep -v "SSL" | grep "error*" )
#//
#ERR_MAKE=$(make 2>&1 | grep -v "warning" | grep  "error*" )
#ERR_MAKE_INST=$(make install 2>&1 | grep -v "warning" | grep "error*" )
mkdir -p /etc/depmod.d
echo 'search extra updates built-in' >/etc/depmod.d/extra.conf
depmod -a
if [[ -z "${FMODE}" ]]; then
	echo -e "$YELLOW FMODE is not indicated. Default value = 0 (4 tuner mode) $NC"
	FMODE=0
fi
if [[ -z "${MSI}" ]]; then
	echo -e "$YELLOW MSI is not indicated. Default value = 1 (enable) $NC"
	MSI=1;
fi
#need to check if ddbridge file is exists.
DDB_CONF_FILE="/etc/modprobe.d/ddbridge.conf"
if [ ! -f "$DDB_CONF_FILE" ]; then
	echo -e "$GREEN ddbridge.conf is created. $NC"
	echo "options ddbridge fmode=$FMODE msi=$MSI" | sudo tee $DDB_CONF_FILE
fi
modprobe ddbridge
cat $DDB_CONF_FILE
modinfo ddbridge | grep 'version:'
# start HW/OS details
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
#
if command -v systemd-detect-virt >/dev/null && VM=$(systemd-detect-virt -v); then
    echo -e "Virtual Machine hypervisor:$VM"
fi
    echo -e "Bash Version:\t$BASH_VERSION"
#
if [ -z "$ERR_MAKE" ] && [ -z "$ERR_MAKE_INST" ]; then
        echo 'Done! Please reboot the server'
else
# end HW/OS details
	echo -e "$RED Errors during drivers building process.$NC"
	echo -e "$RED Please copy output and send to the script author: paliydmn@digitaldevices.de $NC"
	echo -e "$RED Make ERR: \n $ERR_MAKE\nInstall ERR: \n $ERR_MAKE_INST $NC"
	echo -e "$RED $(uname -a) $NC"
fi

