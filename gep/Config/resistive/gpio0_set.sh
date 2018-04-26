#!/bin/bash

# gpio0 --> touchscreen

echo "Pin GPIO_0 RESET ..."
echo out > /sys/class/gpio/gpio0/direction
echo 0 > /sys/class/gpio/gpio0/value
#sleep 3	# eGTouch-v2.5.4330
sleep 6		# eGTouch-v2.5.5814
echo "Pin GPIO_0 SET ..."
echo out > /sys/class/gpio/gpio0/direction
echo 1 > /sys/class/gpio/gpio0/value
exit 0

