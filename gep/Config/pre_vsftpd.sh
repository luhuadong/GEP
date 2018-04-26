#!/bin/bash

Nobody=nobody                          
Empty_Dir=/usr/share/empty             
Ftp_User=ftp
Ftp_Dir=/var/ftp
Guest=virtual 
Guest_Dir=/var/ftproot

#
# vsftpd needs the user "nobody" in the default configuration. 
# Add this user in case it does not already exist.
#
id $Nobody >& /dev/null
#egrep "^$Nobody" /etc/passwd >& /dev/null
if [ $? -ne 0 ]                        
then 
    useradd $Nobody                    
fi  

#
# vsftpd needs the (empty) directory /usr/share/empty in the 
# default configuration. 
# Add this directory in case it does not already exist.
#
if [ ! -d "$Empty_Dir" ]
then
    mkdir -p $Empty_Dir
fi

#
# For anonymous FTP, you will need the user "ftp" to exist, 
# and have a valid home directory (which is NOT owned or 
# writable by the user "ftp").
# The following commands could be used to set up the user "ftp" 
# if you do not have one.
#
if [ ! -d "$Ftp_Dir" ]
then
	mkdir -p $Ftp_Dir
fi

# Create ftp if not exists            
id $Ftp_User >& /dev/null
#egrep "^$Ftp_User" /etc/passwd >& /dev/null
if [ $? -ne 0 ]                        
then 
	useradd -d $Ftp_Dir $Ftp_User
	chown root.root $Ftp_Dir
	chmod og-w $Ftp_Dir
fi  

#
# For Guest FTP
# You should configure /etc/vsftpd.conf like that:
#
#     guest_enable=YES
#     guest_username=virtual
#
# If you want to specify guest login directory, you should:
#
#     local_root=/usr/seat
#
# Add default directory (/var/ftproot)
if [ ! -d "$Guest_Dir" ]
then
	mkdir -p $Guest_Dir
fi

# Create guest if not exists            
id $Guest >& /dev/null
#egrep "^$Guest" /etc/passwd >& /dev/null
if [ $? -ne 0 ]
then
	useradd -d $Guest_Dir -s /sbin/nologin $Guest
	chown $Guest.$Guest $Guest_Dir
	chmod -Rf 755 $Guest_Dir
fi

exit 0
