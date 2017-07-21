#!/bin/bash

APP_NAME = dvblink_server
COMMAND = /volume1/@appstore/DVBLinkServer/start2.sh

  
  ret=$(ps aux | grep [h]$APP_NAME | wc -l)
	if [ "$ret" -eq 0 ]
then {
	echo "Start $APP_NAME"
        sleep 1  #delay
		$COMMAND
	exit 1
}
else 
{
	echo "EXIT. $APP_NAME already running!"
	exit 1
}
fi;
