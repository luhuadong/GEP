#!/bin/bash

cd /opt/aec
chmod a+x adt_aec

if [ -f adt_aec.conf ]; then
	chmod 444 adt_aec.conf
fi

nohup ./adt_aec 2>/dev/null &

exit 0
