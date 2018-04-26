#!/bin/bash

#MACHINE="gy64"
#MACHINE="gy91"
MACHINE="gy71ap"
#MACHINE="pd1707"

#VENDOR="advantech"
#VENDOR="kontron"
VENDOR="norco"

GUI="qt4"
#GUI="qt5"

#MODE="board"
#MODE="host"


ROOT_DIR="/"
Script_Ver="1.00.1003"
Author_Name=Rudy
Author_Mail=luhd@gytchina.com


export MACHINE
export VENDOR

CheckCpuType() {
	ARCH=`uname -m`
	echo "(I) Platform application binary interface = ${ARCH}"
	if [ $ARCH = "x86_64" ]; then
		cpuArch="64"
	elif [ $ARCH = "i386" -o $ARCH = "i586" -o $ARCH = "i686" ]; then
		cpuArch="32"
	elif [ $ARCH = "armv7" -o $ARCH = "armv7l" ]; then
		cpuArch="arm"
	else
		cpuArch="unknown"
	fi

	if [ ${cpuArch} = "arm" ]; then
		MODE="board"
	elif [ ${cpuArch} = "32" -o ${cpuArch} = "64" ]; then
		MODE="host"
	else
		echo "(E) Sorry, the CPU type is unknown."
		echo ""
		exit 1
	fi
}

InitMember() {
	# file name
	touchDriver="eGTouchD"
	touchCalib="eCalib"
	touchConfig="eGTouchL.ini"
	rclocalfile="rc.local"
	interfaces="interfaces"
	bootstrap="bootstrap.sh"
	seat_gw="Seat_Linux"
	seatGwBin="Seat_Linux_11787"
	seat_ui="seat"
	#seatUiBin="seat_imx.tar.gz"
	seatUiBin="seat_imx-2.0.0.11799a.tar.gz"
	seaticon="seat.png"
	logo="psplash"
	logo_gyt="psplash-gyt"
	logo_default="psplash-default"
	gpioScript="gpio_set.sh"

	# path name
	etcpath="${ROOT_DIR}etc"
	usrbinpath="${ROOT_DIR}usr/bin"
	usrsbinpath="${ROOT_DIR}usr/sbin"
	usrlocalbinpath="${ROOT_DIR}usr/local/bin"
	libpath="${ROOT_DIR}lib"
	usrlibpath="${ROOT_DIR}usr/lib"
	usrlocallibpath="${ROOT_DIR}usr/local/lib"
	initpath="${ROOT_DIR}etc/init.d"
	rclocalpath="${ROOT_DIR}etc/rc.local"
	etcModuleFile1="${ROOT_DIR}etc/modules"
	etcpamdpath="${ROOT_DIR}etc/pam.d"
	libsecuritypath="${ROOT_DIR}lib/security"
	homepath="${ROOT_DIR}home/root"
	optpath="${ROOT_DIR}opt"
	seatgwpath="${ROOT_DIR}usr/seat/ata0a"

	etcpath_abs="/etc"
	usrbinpath_abs="/usr/bin"
	usrlibpath_abs="/usr/lib"
	trash="/dev/null"

	pixpath="${ROOT_DIR}usr/share/pixmaps"
	iconpath="${ROOT_DIR}usr/share/icons/Sato"
	applicationpath="${ROOT_DIR}usr/share/applications"
	timezonepath="${ROOT_DIR}usr/share/zoneinfo"
	timezonepath_abs="${ROOT_DIR}usr/share/zoneinfo"

	gepConfigPath="./gep/Config"
	gepMiddlewaresPath="./gep/Middlewares"
	gepDriversPath="./gep/Drivers"
	gepProjectsPath="./gep/Projects"
}

ShowTitle() {
	echo ""
	echo "(*) GYT Easy Package for ARM Linux "
	echo "(*) Script Version = ${Script_Ver}"
	echo ""
}

CheckPermission() {
	echo -n "(I) Check user permission:"
	account=`whoami`
	if [ ${account} = "root" ]; then
		echo " ${account}, you are the supervisor."
	else
		echo " ${account}, you are NOT the supervisor."
		echo "(E) The root permission is required to run this installer."
		echo ""
		exit 1
	fi
}

CheckUinput() {
	UinputPath1="/dev/uinput"
	UinputPath2="/dev/input/uinput"
	uinput=0

	ls ${UinputPath1} 1>${trash} 2>${trash}
	if [ $? = 0]; then
		echo "(I) Found uinput at path $(UinputPath1)"
		uinput=1
	fi

	ls ${UinputPath2} 1>${trash} 2>${trash}
	if [ $? = 0]; then
		echo "(I) Found uinput at path $(UinputPath2)"
		uinput=1
	fi

	if [ ${uinput} != 1 ]; then # Found no uinput file
		checkmod="lsmod"
		modfile="mod.info"
		${checkmod} > ${modfile} 2>${trash}
		grep -q "uinput" ${modfile}

		if [ $? != 0 ]; then # Not found uinput.ko in modules
			checkmodprobe="modprobe -l -a"
			modprobefile="modprobe.info"
			${checkmodprobe} > ${modprobefile} 2>${trash}
			grep -q "uinput" ${modprobefile}
			if [ $? -eq 0 ]; then # Found uinput.ko in modules
				echo "(I) Found uinput.ko in modules."
				Loaduinput="modprobe uinput"
				${Loaduinput} # Load uinput modules
				AttachModuleAtBoot "uinput"
			else
				echo "(E) Can't load uinput module. Please rebuild the module before installation."
				exit 1
			fi
		fi
	fi

	rm -f ${modfile}
	rm -f ${modprobefile}
}

AttachModuleAtBoot() {
	echo "(I) Attach module $1 loaded at boot."
	if [ -w ${etcModuleFile1} ]; then
		grep -q "### Beginning: Load ${1}.ko modules ###" ${etcModuleFile1}
		if [ $? -eq 1 ]; then
			filelines=`cat ${etcModuleFile1} | wc -l`
			sed -i ''${filelines}'a\### Beginning: Load '${1}'.ko modules ###\
			'${1}'### End: Load '${1}'.ko modules###' ${etcModuleFile1}
			echo "(I) Add ${1} module into ${etcModuleFile1} file."
		fi
	else
		echo "(E) Can't add ${1} modules in ${etcModuleFile1}."
		exit 1
	fi
}

DetachModuleAtBoot() {
	if [ -w ${etcModuleFile1} ]; then
		grep -q "Load $1.ko modules" ${etcModuleFile1}
		if [ $? -eq 0 ]; then
			sed -i '/### Beginning: Load $1.ko modules ###/,/### End: Load $1.ko modules###/d' ${etcModuleFile1}
			rmmod $1
			echo "(I) Removed $1 modules from ${etcModuleFile1}."
		fi
	else
		echo "(E) Can't find ${etcModuleFile1} file."
	fi
}

AllotRClocalPath() {
	rclocalModulesPath=${rclocalpath}
}

CheckRClocalExist() {
	if [ ! -e ${rclocalModulesPath} ]; then # rc.local is not exist
		echo "(E) No ${rclocalModulesPath} file found."
		echo ""
		exit 1
	fi
	
	echo "(I) Found ${rclocalModulesPath} file."
}

InstallTouchDriver() {
	echo "TouchScreen install ..."

	which ${touchDriver}
	if [ $? != 0 ]; then
		cp ${gepDriversPath}/EETI/${touchDriver} ${usrbinpath}
		chmod a+x ${usrbinpath}/${touchDriver}
	fi

	which ${touchCalib}
	if [ $? != 0 ]; then
		cp ${gepDriversPath}/EETI/${touchCalib} ${usrbinpath}
		chmod a+x ${usrbinpath}/${touchCalib}
	fi

	if [ ! -f ${etcpath}/${touchConfig} ]; then
		if [ "${MACHINE}" = "gy64" -o "${MACHINE}" = "gy71ap" ]; then # Resistance screen with uart
			if [ "${VENDOR}" = "advantech" ]; then
				cp ${gepDriversPath}/EETI/eGTouchL_ttymxc2.ini ${etcpath}/${touchConfig}
			else
				cp ${gepDriversPath}/EETI/eGTouchL_ttymxc4.ini ${etcpath}/${touchConfig}
			fi
		else # Capacitor screen with usb
			cp ${gepDriversPath}/EETI/eGTouchL.ini ${etcpath}/${touchConfig}
		fi
	fi

	if [ -f ${applicationpath}/xinput_calibrator.desktop ]; then
		# Hide the xinput_calibrator desktop icon
		mv ${applicationpath}/xinput_calibrator.desktop ${applicationpath}/.xinput_calibrator.desktop
	fi

	# Modify /etc/X11/xorg.conf
}

InstallPam() {
	echo "Install PAM framework"
	
	# PAM library

	if false; then
		# WARNING: This operation is not recommended.

		cp ${gepMiddlewaresPath}/pam/lib/libpam.la             ${usrlibpath}
		cp ${gepMiddlewaresPath}/pam/lib/libpam.so.0.84.2      ${usrlibpath}
		cp ${gepMiddlewaresPath}/pam/lib/libpam_misc.la        ${usrlibpath}
		cp ${gepMiddlewaresPath}/pam/lib/libpam_misc.so.0.82.1 ${usrlibpath}
		cp ${gepMiddlewaresPath}/pam/lib/libpamc.la            ${usrlibpath}
		cp ${gepMiddlewaresPath}/pam/lib/libpamc.so.0.82.1     ${usrlibpath}

		ln -s ${usrlibpath_abs}/libpam.so.0.84.2      ${usrlibpath}/libpam.so.0
		ln -s ${usrlibpath_abs}/libpam.so.0           ${usrlibpath}/libpam.so
		ln -s ${usrlibpath_abs}/libpam_misc.so.0.82.1 ${usrlibpath}/libpam_misc.so.0
		ln -s ${usrlibpath_abs}/libpam_misc.so.0      ${usrlibpath}/libpam_misc.so
		ln -s ${usrlibpath_abs}/libpamc.so.0.82.1     ${usrlibpath}/libpamc.so.0
		ln -s ${usrlibpath_abs}/libpamc.so.0          ${usrlibpath}/libpamc.so
	else
		tar zxvf ${gepMiddlewaresPath}/pam/lib/libpam.tar.gz -C ${usrlibpath}
	fi

	# PAM modules ( Always copy security file to target path )

	cp -r ${gepMiddlewaresPath}/pam/security ${libpath}

	# Configure PAM

	if [ ! -d ${etcpamdpath} ]; then
		mkdir -p ${etcpamdpath}
		cp ${gepMiddlewaresPath}/pam/vsftpd ${etcpamdpath}
	fi
}

InstallFtp() {
	echo "Install vsftpd"

	if [ ! -f ${etcpath}/vsftpd.conf ]; then
		cp ${gepMiddlewaresPath}/vsftpd/vsftpd.conf ${etcpath}
	fi

	which vsftpd
	if [ $? != 0 ]; then
		cp ${gepMiddlewaresPath}/vsftpd/vsftpd ${usrsbinpath}
		chmod a+x ${usrsbinpath}/vsftpd
	fi

	if [ ! -e ${optpath}/pre_vsftpd.sh ]; then
		cp ${gepConfigPath}/pre_vsftpd.sh ${optpath}
		chmod a+x ${optpath}/pre_vsftpd.sh
	fi
}

InstallTelnet() {
	echo "Install telnet ( There is nothing to do around here. )"
}

InstallTcpdump() {
	echo "Install tcpdump"

	which tcpdump
	if [ $? != 0 ]; then
		cp ${gepMiddlewaresPath}/tcpdump/tcpdump ${usrsbinpath}
		chmod a+x ${usrsbinpath}/tcpdump
	fi
}

InstallGpioSetup() {
	echo "Install GPIO control script"

	if [ ! -x ${optpath}/${gpioScript} ]; then
		cp ${gepConfigPath}/${gpioScript} ${optpath}
		chmod a+x ${optpath}/${gpioScript}
	fi

	line=`sed -n '/'${gpioScript}'/=' ${gepConfigPath}/bootstrap_${MACHINE}.sh | tail -n1`
	if [ -n "${line}" ]; then
		gpio_cmd="/opt/gpio_set.sh ${MACHINE} ${VENDOR} &"
		sed -i "${line}a${gpio_cmd}" ${gepConfigPath}/bootstrap_${MACHINE}.sh
		sed -i ''${line}'d' ${gepConfigPath}/bootstrap_${MACHINE}.sh
	fi
}

InstallSeatGateway() {
	echo "Install Seat_Linux gateway"

	which iptables
	if [ $? != 0 ]; then
		echo "(E) This Linux OS has not support iptables yet."
		echo ""
		exit 1
	fi

	ls ${seatgwpath}/bin 1>${trash} 2>${trash}
	if [ $? != 0 ]; then
		mkdir -p ${seatgwpath}/bin
	fi

	cp ${gepProjectsPath}/seat_gw/bin/${seatGwBin} ${seatgwpath}/bin/${seat_gw}
	cp ${gepProjectsPath}/seat_gw/bin/nvram.txt ${seatgwpath}/bin/
	cp -r ${gepProjectsPath}/seat_gw/RingVoc ${seatgwpath}
	cp -r ${gepProjectsPath}/seat_gw/Voc ${seatgwpath}

	# Support route nat

	statement1="net.ipv4.conf.default.rp_filter=1"
	statement2="net.ipv4.conf.all.rp_filter=1"
	statement3="net.ipv4.ip_forward=1"

    if [ -w ${etcpath}/sysctl.conf ]; then
		echo "(I) ${etcpath}/sysctl.conf file found."

        line=`sed -n "/#${statement1}/=" ${etcpath}/sysctl.conf | tail -n1`
		echo "line=#${line}#"
        if [ -n "${line}" ]; then
			echo "modify..."
			sed -i "${line}s/#//g" ${etcpath}/sysctl.conf
        fi

        line=`sed -n "/#${statement2}/=" ${etcpath}/sysctl.conf | tail -n1`
		echo "line=${line}"
        if [ -n "${line}" ]; then
			echo "modify..."
			sed -i "${line}s/#//g" ${etcpath}/sysctl.conf
        fi

        line=`sed -n "/#${statement3}/=" ${etcpath}/sysctl.conf | tail -n1`
		echo "line=${line}"
        if [ -n "${line}" ]; then
			echo "modify..."
           sed -i "${line}s/#//g" ${etcpath}/sysctl.conf
        fi
	else
		echo "(E) No ${etcpath}/sysctl.conf file found."
    fi
}

InstallSeatUI() {
	echo "Install Seat user interface over i.mx6 Yocto Linux"

	if [ ! -d ${homepath}/seat_imx ]; then
		echo "(I) Expand ${seatUiBin} into ${homepath}."
		#tar zxvf ${gepProjectsPath}/seat_ui/${seatUiBin} -C ${homepath}
		tar zxf ${gepProjectsPath}/seat_ui/${seatUiBin} -C ${homepath}
	else
		echo "(E) ${homepath}/seat_imx had been exist, please uninstall first."
	fi

	if [ ! "${GUI}" = "qt4" ]; then
		#tar zxvf ${gepProjectsPath}/seat_ui/qt4_lib.tar.gz -C ${homepath}/seat_imx
		tar zxf ${gepProjectsPath}/seat_ui/qt4_lib.tar.gz -C ${homepath}/seat_imx
	fi

	cp ${gepProjectsPath}/seat_ui/icons/seat_16x16.png ${iconpath}/16x16/apps/${seaticon}
	cp ${gepProjectsPath}/seat_ui/icons/seat_22x22.png ${iconpath}/22x22/apps/${seaticon}
	cp ${gepProjectsPath}/seat_ui/icons/seat_32x32.png ${iconpath}/32x32/apps/${seaticon}
	cp ${gepProjectsPath}/seat_ui/icons/seat_48x48.png ${iconpath}/48x48/apps/${seaticon}
	cp ${gepProjectsPath}/seat_ui/icons/seat_64x64.png ${iconpath}/64x64/apps/${seaticon}
	cp ${gepProjectsPath}/seat_ui/icons/seat_64x64.png ${pixpath}/${seaticon}

	cp ${gepProjectsPath}/seat_ui/seat.desktop ${applicationpath}
}

InstallAdtAec() {
	echo "Install ADT Echo cancellation algorithm"

	if [ -d ${optpath}/aec ]; then
		rm -rf ${optpath}/aec
	fi

	if [ ! "${MACHINE}" = "pd1707" ]; then
		cp -r ${gepProjectsPath}/aec ${optpath}
	fi
}

InstallGytBox() {
	echo "Install GYT_BOX"

	if [ -d ${homepath}/tools ]; then
		rm -rf ${homepath}/tools
	fi

	cp -r ${gepProjectsPath}/gyt_box ${homepath}/tools
	mv ${homepath}/tools/gyt_box.png ${pixpath}
	mv ${homepath}/tools/gyt_box.desktop ${applicationpath}
}

InstallGsnap() {
	echo "Install gsnap"
	
	if [ ! -e ${gepMiddlewaresPath}/gsnap/libjpeg.a ]; then
		cp ${gepMiddlewaresPath}/gsnap/libjpeg.a ${usrlibpath}		
	fi
	if [ ! -e ${gepMiddlewaresPath}/gsnap/libjpeg.la ]; then
		cp ${gepMiddlewaresPath}/gsnap/libjpeg.la ${usrlibpath}
	fi
	if [ ! -x ${gepMiddlewaresPath}/gsnap/libjpeg.so.9.2.0 ]; then
		cp ${gepMiddlewaresPath}/gsnap/libjpeg.so.9.2.0 ${usrlibpath}
		ln -s ${usrlibpath_abs}/libjpeg.so.9.2.0 ${usrlibpath}/libjpeg.so.9
	fi

	cp ${gepMiddlewaresPath}/gsnap/gsnap ${usrbinpath}
	chmod a+x ${usrbinpath}/gsnap
}

InstallBootstrap() {
	echo "Install bootstrap script file"

	if [ -e ${gepConfigPath}/bootstrap_${MACHINE}.sh ]; then
		cp -f ${gepConfigPath}/bootstrap_${MACHINE}.sh ${etcpath}/${bootstrap}
		chmod a+x ${etcpath}/${bootstrap}
	else
		echo "(E) No ${gepConfigPath}/bootstrap_${MACHINE}.sh file found."
		echo ""
		exit 1
	fi

	if [ ${VENDOR} = "kontron" -a ${MACHINE} = "gy71ap" ]; then
		ln -s ${etcpath_abs}/${bootstrap} ${etcpath}/rc5.d/S99gytboot
	else
		line=`sed -n '/exit 0/=' ${rclocalModulesPath} | tail -n1`
		sed -i "${line}i${etcpath}/${bootstrap}" ${rclocalModulesPath}
	fi

}

SetNetwork() {
	echo "Set network"
	
	if [ "${MACHINE}" = "gy64" ]; then
		cp ${gepConfigPath}/network/interfaces_single_${VENDOR} ${etcpath}/network/${interfaces}
	elif [ "${MACHINE}" = "gy91" -o "${MACHINE}" = "gy71ap" -o "${MACHINE}" = "pd1707" ]; then
		cp ${gepConfigPath}/network/interfaces_double_${VENDOR} ${etcpath}/network/${interfaces}
	else
		echo ""
	fi
}

SetTimezone() {
	echo "Set timezone to Shanghai (CST/UTC+8)"

	if [ -e ${etcpath}/localtime ]; then
		rm -f ${etcpath}/localtime
	fi

	if [ -e ${timezonepath}/Asia/Shanghai ]; then
		ln -s ${timezonepath_abs}/Asia/Shanghai ${etcpath}/localtime 
	else
		cp ${gepConfigPath}/timezone/Shanghai ${etcpath}/localtime
	fi

	#cp ${gepConfigPath}/clock /etc/sysconfig/
}

SetPsplash() {
	echo "Set GYT boot/shutdown screen"

	if [ -e ${usrbinpath}/${logo} ]; then
		rm -f ${usrbinpath}/${logo}
	fi

	cp ${gepMiddlewaresPath}/psplash/${logo_gyt} ${usrbinpath}
	chmod a+x ${usrbinpath}/${logo_gyt}
	ln -s ${usrbinpath_abs}/${logo_gyt} ${usrbinpath}/${logo}
}

SetRecordPath() {
	echo "Set record path for seat_imx using mstat flash"

	if [ ${MACHINE} = "gy71ap" ]; then
		if [ ! -e ${etcpath}/fstab ]; then
			echo "(E) No ${etcpath}/fstab file found."
			exit 1
		fi
	
		if [ ! -d ${homepath}/video ]; then
			mkdir -p ${homepath}/video
		fi
	
		cat ${etcpath}/fstab | grep "video" 1>${trash} 2>${trash}
		if [ $? != 0 ]; then
			fstab_cmd="/dev/sda1           /home/root/video      auto       defaults,sync,noauto  0  0"
			line=`cat ${etcpath}/fstab | wc -l`
			sed -i "${line}i${fstab_cmd}" ${etcpath}/fstab
		fi

	fi
}

GepInstall() {
	echo "(I) GEP Install packages ..."
	echo ""

	InstallTouchDriver
	InstallPam
	InstallFtp
	InstallTelnet
	InstallTcpdump
	InstallSeatGateway
	InstallSeatUI
	InstallAdtAec
	InstallGytBox
	InstallGpioSetup
	InstallGsnap
	InstallBootstrap

	SetPsplash
	SetRecordPath 
	SetNetwork
	SetTimezone
	sync
	
	echo "Done! GEP install finished."
	echo ""
}

KillProcess() {

	if [ -z "$1" ]; then
		echo "(I) KillProcess: Nothing to do."
		return
	fi

	process="$1"

	if [ ${VENDOR} = "kontron" ]; then
		PID=`ps | grep "${process}" | grep -v grep | awk '{print $1}'`
	else
		PID=`ps -ef | grep "${process}" | grep -v grep | awk '{print $2}'`
	fi

	if [ -n "${PID}" ]; then
		kill ${PID}
	else
		echo "(W) No ${process} process."
	fi
}

GepUninstall() {
	echo "(I) GEP Uninstall packages ..."
	echo ""

	KillProcess "${seat_ui}"
	KillProcess "${seat_gw}"
	KillProcess "vsftpd"
	KillProcess "tcpdump"
	KillProcess "detectTouch.sh"
	KillProcess "${touchDriver}"
	KillProcess "${touchCalib}"
	KillProcess "adt_aec"
	KillProcess "gyt_box"
	KillProcess "gsnap"

	rm -f ${usrbinpath}/${logo}
	ln -s ${usrbinpath_abs}/${logo_default} ${usrbinpath}/${logo}

	lineNum=`sed -n -e '/video/=' ${etcpath}/fstab | tail -n1`
	if [ -n "${lineNum}" ]; then
		sed -i ''${lineNum}'d' ${etcpath}/fstab
	fi

	lineNum=`sed -n -e '/'${bootstrap}'/=' ${rclocalModulesPath} | tail -n1`
	if [ -n "${lineNum}" ]; then
		sed -i ''${lineNum}'d' ${rclocalModulesPath}
	fi
	if [ -e ${etcpath}/rc5.d/S99gytboot ]; then
		rm -f ${etcpath}/rc5.d/S99gytboot 
	fi
	rm -f ${etcpath}/${bootstrap}

	rm -f ${usrbinpath}/gsnap
	rm -f ${optpath}/${gpioScript}
	rm -rf ${homepath}/tools
	rm -rf ${optpath}/aec

	rm -rf ${homepath}/seat_imx
	rm -f ${applicationpath}/seat.desktop

	rm -rf ${seatgwpath}
	rm -f ${usrsbinpath}/tcpdump
	rm -f ${usrsbinpath}/vsftpd
	rm -rf ${etcpath}/vsftpd*
	rm -rf ${optpath}/pre_vsftpd.sh
	rm -rf ${usrlibpath}/libpam*
	rm -rf ${libpam}/security/*
	rm -rf ${etcpamdpath}

	rm -f ${usrbinpath}/${touchDriver}
	rm -f ${usrbinpath}/${touchCalib}
	rm -f ${etcpath}/${touchConfig}

	echo "Done! GEP uninstall finished."
	echo ""
}


clear
ShowTitle
CheckCpuType
CheckPermission

InitMember
AllotRClocalPath
CheckRClocalExist

if [ $1 = "-r" ]; then
	GepUninstall
else
	GepInstall
fi

echo -n "Do you want to reboot now? [Y/N]: "
while : ; do
	read key
	case $key in
		y|Y) reboot
		     break;;
		n|N) echo "(I) Exit GEP completely."
		     break;;
		*)	 echo "(I) Please choose [Y] or [N]"
			 echo -n "(A) "
			 ;;
	esac
done

exit 0

