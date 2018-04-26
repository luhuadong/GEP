#!/bin/bash

# #################################################
#
# For NORCO:
#
# CPIO0 (SMARC) <-->
# GPIO1 (SMARC) <--> GPIO3_IO01 (num=65)
# GPIO2 (SMARC) <--> GPIO3_IO02 (num=66)
# GPIO3 (SMARC) <-->
#
# #################################################

#MACHINE="gy64"
#MACHINE="gy91"
MACHINE="gy71ap"
#MACHINE="pd1707"

VENDOR="advantech"
#VENDOR="kontron"
#VENDOR="norco"

if [ -n "$1" ]; then
	MACHINE=$1
fi

if [ -n "$2" ]; then
	VENDOR=$2
fi

CheckParameter() {

	if [ "${MACHINE}" = "gy64" -o "${MACHINE}" = "gy91" -o "${MACHINE}" = "gy71ap" -o "${MACHINE}" = "pd1707" ]; then
		echo "(I) Machine ${MACHINE} is supported."
	else
		echo "(E) Machine ${MACHINE} is not supported."
		exit 1
	fi

	if [ "${VENDOR}" = "advantech" -o "${VENDOR}" = "kontron" -o "${VENDOR}" = "norco" ]; then
		echo "(I) Vendor ${VENDOR} is supported."
	else
		echo "(E) Vendor ${VENDOR} is not supported."
		exit 1
	fi
}

InitGpio() {

	if [ "$VENDOR" = "advantech" ]; then
		GPIO_TOUCH=2
		GPIO_CAMERA=3
	elif [ "$VENDOR" = "kontron" ]; then
		GPIO_TOUCH=1
		GPIO_CAMERA=2
	elif [ "$VENDOR" = "norco" ]; then
		GPIO_TOUCH=65
		GPIO_CAMERA=66
	else
		GPIO_TOUCH=1
		GPIO_CAMERA=2
	fi

	echo "GPIO_TOUCH=$GPIO_TOUCH"
	echo "GPIO_CAMERA=$GPIO_CAMERA"
}

ExportGpio() {

	if [ ! -d /sys/class/gpio/gpio$GPIO_TOUCH ]; then 
		echo $GPIO_TOUCH  > /sys/class/gpio/export
		echo "/sys/class/gpio/gpio$GPIO_TOUCH"
	fi

	if [ ! -d /sys/class/gpio/gpio$GPIO_CAMERA ]; then 
		echo $GPIO_CAMERA > /sys/class/gpio/export
		echo "/sys/class/gpio/gpio$GPIO_CAMERA"
	fi
}

SetGpio() {

	if [ "$MACHINE" = "gy64" ] || [ "$MACHINE" = "gy71ap" ]; then
		echo out > /sys/class/gpio/gpio$GPIO_TOUCH/direction
		echo 0   > /sys/class/gpio/gpio$GPIO_TOUCH/value
	fi

	if [ "$MACHINE" = "gy71ap" ] || [ "$MACHINE" = "pd1707" ]; then
		echo out > /sys/class/gpio/gpio$GPIO_CAMERA/direction
		echo 0   > /sys/class/gpio/gpio$GPIO_CAMERA/value
	fi

	# According to the timing sequence

	if [ "$MACHINE" = "gy64" ] || [ "$MACHINE" = "gy71ap" ]; then
		sleep 5
		echo out > /sys/class/gpio/gpio$GPIO_TOUCH/direction
		echo 1   > /sys/class/gpio/gpio$GPIO_TOUCH/value
	fi
}

CheckParameter
InitGpio
ExportGpio
SetGpio

exit 0

