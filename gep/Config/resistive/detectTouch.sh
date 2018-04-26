#!/bin/bash

NormalName="eGalaxTouch"
AbnormalName="EETI"

sleep 6
echo "Start Detect TouchScreen ..."

touchOk=20

while(( "$touchOk" > 0))
do
	PID=`ps | grep eGTouchD | grep -v grep | awk '{print $1}'`
	if [ -z $PID ]
	then
		#echo "PID is NULL"
		/usr/bin/eGTouchD
		sleep 2
	else
		#echo "PID eq" $PID
		lineNum=`sed -n -e '/Vendor=0eef Product=0010/=' /proc/bus/input/devices`
		endNum=`expr $lineNum + 9`
		tsName=`sed -n "$lineNum"','"$endNum"'p' /proc/bus/input/devices | grep $NormalName`
		#echo "tsName =" $tsName
		if [ -z "$tsName" ]
		then 
			# echo "kill" $PID
			# kill $PID
			# sleep 1
			/usr/bin/eGTouchD -f
			sleep 1
		else
			#echo "touch is Ok."
			touchOk=`expr $touchOk - 1`
		fi
	fi

	sleep 5
done

#echo "touch Ok."

#PID=`ps | grep eGTouchD | grep -v grep | awk '{print $1}'`
#echo $PID

#if [ -z $PID ]
#then echo "PID is null"
#else echo "PID eq" $PID
#fi

#lineNum=`sed -n -e '/Vendor=0eef/=' /proc/bus/input/devices`
#echo "line number :" $lineNum
#endNum=`expr $lineNum + 9`
#echo "end :" $endNum
#tsName=`sed -n "$lineNum"','"$endNum"'p' /proc/bus/input/devices | grep $NormalName`
#echo "tsName:"$tsName


#/usr/bin/eGTouchD
#echo "Finish Detect."
exit 0
