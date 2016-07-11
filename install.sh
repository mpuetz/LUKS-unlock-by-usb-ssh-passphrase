#! /bin/bash
# This script is based on the scripts luks-triple-unlock from chadoe (aka Martin van Beurden as found at https://github.com/chadoe/luks-triple-unlock)
# and decryptkeydevice by Franco_bez (https://ubuntuusers.de/user/franco_bez/) as found at (https://wiki.ubuntuusers.de/System_verschl%C3%BCsseln/Entschl%C3%BCsseln_mit_einem_USB-Schl%C3%BCssel/#Anlegen-der-noetigen-Konfigurationsdateien)
# The scripts were adapted and combined by mpuetz (Michael Pütz, https://github.com/mpuetz/LUKS-unlock-by-usb-ssh-passphrase) to 
# get the best from both worlds and having a fully automated script doing all the work for you.
# This script may be used under the MIT-License (https://github.com/mpuetz/LUKS-unlock-by-usb-ssh-passphrase/blob/master/LICENSE).

# getting the needed informations about the device.
echo "Please use 'sudo fdisk -l' and write down the name of the device you want to decrypt and the name of your usb-drive (sda; sdb...)."
echo "You will also need the UUID of your usb-drive (you can get it by executing 'sudo ls -l /dev/disk/by-id'), the blocksize and the beginning of the first partiton (you can get it by executing 'sudo fdisk -l /dev/name-of-your-usb-drive')."
echo "Have you written down all the informations?"
echo "y=yes, n=no"
read -p "prepared?: " prepared
if [ $prepared == "y" ]
        then
                echo "Please enter the usb disk-id now (sda, sdb, sdc... without the partition numbers!)"
                read devuuid
                echo "Please enter the usb uuid now (e.g. usb-XyzFlash_XYZDFGHIJK_XXYYZZ00AA-0:0   or   mmc-XXX_0x0AAABBBCCCDDD)"
                read usbuuid
                echo "Please enter the blocksize"
                read blocksize
                echo "Please enter the sector, the first partition starts at"
                read firstpart
                echo "please enter the sector you want the key to start at"
                read sectorstart
                while [ $sectorstart -le "0" ]
                        do
                                echo "0 and less are not allowed as the start sector. Please enter another startsector."
                                read sectorstart
                        done
                echo "please enter the sector you want the key to end at"
                read sectorend
		okay="0"
		while [ $okay -eq 0 ]
			do
				keysize=$(( ( $sectorend - $sectorstart ) * $blocksize ))
				echo "your key will be "$keysize" bytes. Is that okay?"
				echo "0=no, 1=yes"
				read okay
				if [ $okay == "0" ]
					then
						echo "Please enter the sector you want the key to start at."
						read sectorstart
						while [ $sectorstart -le "0" ]
							do
							echo "0 and less are not valid startsectors. Please enter another."
							read sectorstart
						done
						echo "Please enter the sector you want your key to end at."
						read sectorend
				elif [ $okay == "1" ]
					then
						echo "Great! Continuing"
				else
						okay="0"
				fi
			done
                if [ "$devuuid" == "" ] || [ "$blocksize" == "" ] || [ "$sectorstart" == "" ] || [ "$sectorend" == "" ]
                        then
                                echo "something went terribly wrong. Aborting"
                                exit 255
                fi
        skipblocks=$sectorstart
        readblocks=$(( $sectorend - $sectorstart ))
elif [ $prepared == "n" ]
        then
                echo "well, then do that now ;)"
                exit 0
else
                echo "Aborted"
                exit 255
fi

morecryptdevices="0"
while [ $morecryptdevices == "0" ]
do
# adding the key to the device
if [ $devuuid == "/dev/*"]
	then
		devuuid=${devuuid##/dev/}
fi

if [ $devuuid == "*/" ]
	then
		devuuid=${devuuid%/}
fi
writeblocks=$(( firstpart - 1))
dd if=/dev/urandom of=/dev/$devuuid bs=$blocksize seek=$sectorstart count=$writeblocks && echo "creating the key was successful!"

# create a file from the key for adding the key to LUKSsetup
dd if=/dev/$devuuid bs=$blocksize skip=$skipblocks count=$readblocks > /tmp/tempKeyFile.bin

echo "Please enter the name of the drive you want to unlock with the usb-key (e.g. /dev/sda9)"
read devicename
cryptsetup luksAddKey $devicename /tmp/tempKeyFile.bin

#add the script to crypttab
echo "Getting first cryptodisk in /etc/crypttab"
lowestlinenr=9999
for diskid in $(blkid -t TYPE=crypto_LUKS -o value -s UUID $devicename); do
    linenr=$(awk 'match($0,v){print NR; exit}' v=$diskid /etc/crypttab)
    echo "Found $diskid on line $linenr"
    if [ $linenr -lt $lowestlinenr ]; then
#        if [ $diskid == $devicename ]; then
		cryptUUID=$diskid
#        fi
        lowestlinenr=$linenr
    fi
done
if [ -z "$cryptUUID" ]; then
    echo "Unable to find a cryptodisk to use, exiting."
    exit 1
fi
echo "Using cryptodisk $cryptUUID"
#remove any previous keyscript
sed -i "/$cryptUUID/ s/,keyscript=[^, \t]*//" /etc/crypttab
#add our keyscript
sed -i "/$cryptUUID/ s/\$/,keyscript=\/etc\/decryptkeydevice\/decryptkeydevice_keyscript.sh/" /etc/crypttab

morecryptdevices="0"
while [ $morecryptdevices == "1" ]
do
echo "do you want to add the key to more devices? 0=no, 1=yes"
read morecryptdevices
if [ $morecryptdevices == "1" ]
then
echo "Please enter the name of the drive you want to unlock with the usb-key (e.g. /dev/sda9)"
read devicename
cryptsetup luksAddKey $devicename /tmp/tempKeyFile.bin

#add the script to crypttab
echo "Getting first cryptodisk in /etc/crypttab"
lowestlinenr=9999
for diskid in $(blkid -t TYPE=crypto_LUKS -o value -s UUID $devicename); do
    linenr=$(awk 'match($0,v){print NR; exit}' v=$diskid /etc/crypttab)
    echo "Found $diskid on line $linenr"
    if [ $linenr -lt $lowestlinenr ]; then
#        if [ $diskid == $devicename ]; then
		cryptUUID=$diskid
#        fi
        lowestlinenr=$linenr
    fi
done
if [ -z "$cryptUUID" ]; then
    echo "Unable to find a cryptodisk to use, exiting."
    exit 1
fi
echo "Using cryptodisk $cryptUUID"
#remove any previous keyscript
sed -i "/$cryptUUID/ s/,keyscript=[^, \t]*//" /etc/crypttab
#add our keyscript
sed -i "/$cryptUUID/ s/\$/,keyscript=\/etc\/decryptkeydevice\/decryptkeydevice_keyscript.sh/" /etc/crypttab
fi
done

rm -f /tmp/tempKeyFile.bin

#Check if the folder for the script and config-file already exists and otherwise creating the folder. 
if [ -d /etc/decryptkeydevice/ ]
	then
		echo "folder already exists"
else
		mkdir /etc/decryptkeydevice/ && echo "folder successfully created!"
fi

# checking if the unlocking-file already exists. when it does, it will be moved.
if [ -f /etc/decryptkeydevice/decryptkeydevice_keyscript.sh ]
	then
		echo "file already exists, moving to /etc/decryptkeydevice/decryptkeydevice_keyscript.sh.old"
		mv /etc/decryptkeydevice/decryptkeydevice_keyscript.sh /etc/decryptkeydevice/decryptkeydevice_keyscript.sh.old
fi

# checking if the configuration-file already exists. when it does, it will be moved.
if [ -f /etc/decryptkeydevice/decryptkeydevice.conf ]
	then
		echo "file already exists, moving to /etc/decryptkeydevice/decryptkeydevice.conf.old"
		mv /etc/decryptkeydevice/decryptkeydevice.conf /etc/decryptkeydevice/decryptkeydevice.conf.old
fi

# creating conf-file for unlocking
cat << EOF>/etc/decryptkeydevice/decryptkeydevice.conf
# configuration for decryptkeydevice
#

# ID(s) of the USB/MMC key(s) for decryption (sparated by blanks)
# as listed in /dev/disk/by-id/
DECRYPTKEYDEVICE_DISKID="$usbuuid"

# blocksize usually 512 is OK
DECRYPTKEYDEVICE_BLOCKSIZE="$blocksize"

# start of key information on keydevice DECRYPTKEYDEVICE_BLOCKSIZE * DECRYPTKEYDEVICE_SKIPBLOCKS
DECRYPTKEYDEVICE_SKIPBLOCKS="$skipblocks"

# length of key information on keydevice DECRYPTKEYDEVICE_BLOCKSIZE * DECRYPTKEYDEVICE_READBLOCKS
DECRYPTKEYDEVICE_READBLOCKS="$readblocks"
EOF

# creating unlocking-script
cat << EOF>/etc/decryptkeydevice/decryptkeydevice_keyscript.sh
#!/bin/sh
#
# original file name crypto-usb-key.sh
# heavily modified and adapted for "decryptkeydevice" by Franco
#
### original header :
#
# Part of passwordless cryptofs setup in Debian Etch.
# See: http://wejn.org/how-to-make-passwordless-cryptsetup.html
# Author: Wejn <wejn at box dot cz>
#
# Updated by Rodolfo Garcia (kix) <kix at kix dot com>
# For multiple partitions
# http://www.kix.es/
#
# Updated by TJ <linux@tjworld.net> 7 July 2008
# For use with Ubuntu Hardy, usplash, automatic detection of USB devices,
# detection and examination of *all* partitions on the device (not just partition #1), 
# automatic detection of partition type, refactored, commented, debugging code.
#
# Updated by Hendrik van Antwerpen <hendrik at van-antwerpen dot net> 3 Sept 2008
# For encrypted key device support, also added stty support for not
# showing your password in console mode.

# define counter-intuitive shell logic values (based on /bin/true & /bin/false)
# NB. use FALSE only to *set* something to false, but don't test for
# equality, because a program might return any non-zero on error

# Updated by Dominique Bellenger <dev at domesdomain dot de>
# for usage with Ubuntu 10.04 Lucid Lynx
# - Removed non working USB device check
# - changed vol_id to blkid, changed sed expression
# - changed TRUE and FALSE to be 1 and 0
# - changed usplash usage to plymouth usage
# - removed possibility to read from an encrypted device (why would I want to do this? The script is unnecessary if I have to type in a password)
#
### original header END

# read decryptkeydevice Key configuration settings
DECRYPTKEYDEVICE_DISKID=""
if [ -f /etc/decryptkeydevice/decryptkeydevice.conf ] ; then
		.  /etc/decryptkeydevice/decryptkeydevice.conf
fi

TRUE=1
FALSE=0

# set DEBUG=\$TRUE to display debug messages, DEBUG=\$FALSE to be quiet
DEBUG=\$TRUE

PLYMOUTH=\$FALSE
# test for plymouth and if plymouth is running
if [ -x /bin/plymouth ] && plymouth --ping; then
        PLYMOUTH=\$TRUE
fi

# is usplash available? default false
USPLASH=\$FALSE
# test for outfifo from Ubuntu Hardy cryptroot script, the second test
# alone proves not completely reliable.
if [ -p /dev/.initramfs/usplash_outfifo -a -x /sbin/usplash_write ]; then
    # use innocuous command to determine if usplash is running
    # usplash_write will return exit-code 1 if usplash isn't running
    # need to set a flag to tell usplash_write to report no usplash
    FAIL_NO_USPLASH=1
    # enable verbose messages (required to display messages if kernel boot option "quiet" is enabled
    /sbin/usplash_write "VERBOSE on"
    if [ \$? -eq \$TRUE ]; then
        # usplash is running
        USPLASH=\$TRUE
        /sbin/usplash_write "CLEAR"
    fi
fi

# is stty available? default false
STTY=\$FALSE
STTYCMD=false
# check for stty executable
if [ -x /bin/stty ]; then
	STTY=\$TRUE
	STTYCMD=/bin/stty
elif [ `(busybox stty >/dev/null 2>&1; echo \$?)` -eq 0 ]; then
	STTY=\$TRUE
	STTYCMD="busybox stty"
fi

# print message to plymouth or stderr
# usage: msg "message" [switch]
# switch : switch used for echo to stderr (ignored for plymouth)
# when using plymouth the command will cause "message" to be
# printed according to the "plymouth message" definition.
# using the switch -n will allow echo to write multiple messages
# to the same line
msg ()
{
	if [ \$# -gt 0 ]; then
		# handle multi-line messages
		echo \$2 | while read LINE; do
			if [ \$PLYMOUTH -eq \$TRUE ]; then
				/bin/plymouth message --text="\$1 \$LINE"
			elif [ \$USPLASH -eq \$TRUE ]; then
                		# use usplash
				/sbin/usplash_write "\$1 \$LINE"
			else
				# use stderr for all messages
				echo $3 "\$2" >&2
			fi
		done
	fi
}

dbg ()
{
	if [ \$DEBUG -eq \$TRUE ]; then
		msg "\$@"
	fi
}

plymouth_readpass ()
{
    local PASS PLPID
    local PIPE=/lib/cryptsetup/passfifo
    mkfifo -m 0600 \$PIPE
    plymouth ask-for-password --prompt "\$1"  >\$PIPE &PLPID=\$!
    read PASS <\$PIPE
    kill \$PLPID >/dev/null 2>&1
    rm -f \$PIPE
    echo "\$PASS"
}

# read password from console or with plymouth
# usage: readpass "prompt"
readpass ()
{
	if [ \$# -gt 0 ]; then
		if [ \$PLYMOUTH -eq \$TRUE ]; then
			PASS=\$(plymouth_readpass "\$1")
		elif [ \$USPLASH -eq \$TRUE ]; then
            		msg TEXT "WARNING No SSH unlock support available"
			usplash_write "INPUTQUIET \$1"
            		PASS="\$(cat /dev/.initramfs/usplash_outfifo)"
        	elif [ -f /lib/cryptsetup/askpass ]; then
			PASS=\$(/lib/cryptsetup/askpass "\$1")
		else
			msg TEXT "WARNING No SSH unlock support available"
			[ \$STTY -ne \$TRUE ] && msg "WARNING stty not found, password will be visible"
			echo -n "\$1" >&2
			\$STTYCMD -echo
			read -r PASS </dev/console >/dev/null
			[ \$STTY -eq \$TRUE ] && echo >&2
			\$STTYCMD echo
		fi
	fi
	echo -n "\$PASS"
}

# flag tracking key-file availability
OPENED=\$FALSE

# decryptkeydevice configured so try to find a key
if [ ! -z "\$DECRYPTKEYDEVICE_DISKID" ]; then
	msg "Checking devices for decryption key ..."
	# Is the USB driver loaded?
	cat /proc/modules | busybox grep usb_storage >/dev/null 2>&1
	USBLOAD=0\$?
	if [ \$USBLOAD -gt 0 ]; then
		dbg "Loading driver 'usb_storage'"
		modprobe usb_storage >/dev/null 2>&1
	fi
	# Is the mmc_block driver loaded?
	cat /proc/modules | busybox grep mmc >/dev/null 2>&1
	MMCLOAD=0\$?
	if [ \$MMCLOAD -gt 0 ]; then
		dbg "Loading drivers for 'mmc'"
		modprobe mmc_core >/dev/null 2>&1
		modprobe ricoh_mmc >/dev/null 2>&1
		modprobe mmc_block >/dev/null 2>&1
		modprobe sdhci >/dev/null 2>&1
	fi

	# give the system time to settle and open the devices
	sleep 5

	for DECRYPTKEYDEVICE_ID in \$DECRYPTKEYDEVICE_DISKID ; do
		DECRYPTKEYDEVICE_FILE="/dev/disk/by-id/\$DECRYPTKEYDEVICE_ID"
		dbg "Trying disk/by-id/\$DECRYPTKEYDEVICE_FILE ..."
		if [ -e \$DECRYPTKEYDEVICE_FILE ] ; then
			dbg " found disk/by-id/\$DECRYPTKEYDEVICE_FILE ..."
			OPENED=\$TRUE
			break
		fi
		\$DECRYPTKEYDEVICE_FILE=""
	done
fi

# clear existing usplash text and status messages
[ \$USPLASH -eq \$TRUE ] && msg STATUS "                               " && msg CLEAR ""

if [ \$OPENED -eq \$TRUE ]; then
	/bin/dd if=\$DECRYPTKEYDEVICE_FILE bs=\$DECRYPTKEYDEVICE_BLOCKSIZE skip=\$DECRYPTKEYDEVICE_SKIPBLOCKS count=\$DECRYPTKEYDEVICE_READBLOCKS 2>/dev/null
	if [ \$? -eq 0 ] ; then
		dbg "Reading key from '\$DECRYPTKEYDEVICE_FILE' ..."
	else
		dbg "FAILED Reading key from '\$DECRYPTKEYDEVICE_FILE' ..."
		OPENED=\$FALSE
	fi
fi

if [ \$OPENED -ne \$TRUE ]; then
	msg "FAILED to find suitable Key device. Plug in now and press enter, or"
	readpass "Enter passphrase: "
	msg " "
else
	msg "Success loading key from '\$DECRYPTKEYDEVICE_FILE'"
fi

[ \$USPLASH -eq \$TRUE ] && /sbin/usplash_write "VERBOSE default"
EOF
chmod +x /etc/decryptkeydevice/decryptkeydevice_keyscript.sh

# adding the hook-script
cat <<EOF >/etc/initramfs-tools/hooks/decryptkeydevice.hook
#!/bin/sh
# copy decryptkeydevice files to initramfs
#

mkdir -p \$DESTDIR/etc/
cp -rp /etc/decryptkeydevice \$DESTDIR/etc/
EOF
chmod +x /etc/initramfs-tools/hooks/decryptkeydevice.hook

#Dropbear ssh unlock
apt-get install -y dropbear initramfs-tools busybox

#explicitely enable dropbear (=default behavior), won't touch existing setting if any
(grep -qs '^DROPBEAR=' /etc/initramfs-tools/conf.d/dropbear || \
 grep '^DROPBEAR=' /etc/initramfs-tools/initramfs.conf || \
 echo 'DROPBEAR=y' \
) >> /etc/initramfs-tools/conf.d/dropbear
#explicitely set ip to dhcp (=default behavior), won't touch existing setting if any
(grep -qs '^IP=' /etc/initramfs-tools/conf.d/dropbear || \
 grep '^IP=' /etc/initramfs-tools/initramfs.conf || \
 echo 'IP=dhcp' \
) >> /etc/initramfs-tools/conf.d/dropbear
#disallow password logins (=non-default behavior), set port to 22 (=default behavior), won't touch existing setting if any
(grep -qs 'PKGOPTION_dropbear_OPTION=' /etc/initramfs-tools/conf.d/dropbear || \
 grep 'PKGOPTION_dropbear_OPTION=' /etc/initramfs-tools/initramfs.conf || \
 echo 'PKGOPTION_dropbear_OPTION="-s -p 22"' \
) >> /etc/initramfs-tools/conf.d/dropbear

#Private key of root needed to login to dropbear
#Generate a key if none exists for convenience as this was done in older versions as well
if [ ! -f /etc/initramfs-tools/root/.ssh/id_rsa ]; then
    mkdir -p /etc/initramfs-tools/root/.ssh
    ssh-keygen -t rsa -N '' -f /etc/initramfs-tools/root/.ssh/id_rsa
    cat /etc/initramfs-tools/root/.ssh/id_rsa.pub >> /etc/initramfs-tools/root/.ssh/authorized_keys
fi

#Write initramfs scripts
#
cat << DONE > /etc/initramfs-tools/hooks/crypt_unlock.sh
#!/bin/sh
 
PREREQ="dropbear"
 
prereqs() {
    echo "$PREREQ"
}
 
case "\$1" in
    prereqs)
        prereqs
        exit 0
    ;;
esac
 
. "\${CONFDIR}/initramfs.conf"
. /usr/share/initramfs-tools/hook-functions
 
if [ "\${DROPBEAR}" != "n" ] && [ -r "/etc/crypttab" ] ; then
    #run unlock on ssh login
    echo unlock>>"\${DESTDIR}/etc/profile"
	#write the unlock script
    cat > "\${DESTDIR}/bin/unlock" << EOF
#!/bin/sh

# Read passphrase
read_pass()
{
    # Disable echo.
    stty -echo

    # Set up trap to ensure echo is enabled before exiting if the script
    # is terminated while echo is disabled.
    trap 'stty echo' EXIT SIGINT

    # Read passphrase.
    read "\\\$@"

    # Enable echo.
    stty echo
    trap - EXIT SIGINT

    # Print a newline because the newline entered by the user after
    # entering the passcode is not echoed. This ensures that the
    # next line of output begins at a new line.
    echo
}

printf "Enter passphrase: "
read_pass password
echo "\\\$password" >/lib/cryptsetup/passfifo 

EOF
 
    chmod +x "\${DESTDIR}/bin/unlock"

    echo On successful unlock this ssh-session will disconnect. >> \${DESTDIR}/etc/motd
    echo Run \"unlock\" to get passphrase prompt back if you end up in the shell. >> \${DESTDIR}/etc/motd
fi
DONE
chmod +x /etc/initramfs-tools/hooks/crypt_unlock.sh

#Write initramfs scripts
#
#Network won't be reconfigured after dropbear has initialized it in initramfs, reset it
#
cat <<EOF >/etc/initramfs-tools/scripts/local-bottom/reset_network
#!/bin/sh
#
# Initramfs script to reset all network devices after initramfs is done.
#
# Author: Martin van Beurden, https://martinvanbeurden.nl
#
# Usage:
# - Copy this script to /etc/initramfs-tools/scripts/local-bottom/reset_network
# - chmod +x /etc/initramfs-tools/scripts/local-bottom/reset_network
# - update-initramfs -u -k -all
#
PREREQ=""
prereqs()
{
    echo "$PREREQ"
}
case \$1 in
    prereqs)
        prereqs
        exit 0
    ;;
esac
#
# Begin real processing
#
ifaces=\$(ip addr|egrep "^[0-9]*: "|egrep -v "^[0-9]*: lo:"|awk '{print \$2}'|sed 's/:\$//g')
for iface in \$ifaces; do
    echo "Flushing network interface \$iface"
    ip addr flush \$iface
done
EOF

chmod +x /etc/initramfs-tools/scripts/local-bottom/reset_network

#
#Just an extra, kills the dropbear connecton when done so the client 
#knows immediately it has been disconnected.
#
cat << EOF>/etc/initramfs-tools/scripts/local-bottom/kill_dropbear_connections
#!/bin/sh

# Initramfs script to kill all dropbear clientconnections after initramfs is done.
#
# Adopted from openwrt
# Author: Martin van Beurden, https://martinvanbeurden.nl
#
# Usage:
# - Copy this script to /etc/initramfs-tools/scripts/local-bottom/kill_dropbear_connections
# - chmod +x /etc/initramfs-tools/scripts/local-bottom/kill_dropbear_connections
# - update-initramfs -u -k -all
#
PREREQ=""
prereqs()
{
    echo "\$PREREQ"
}
case \$1 in
    prereqs)
        prereqs
        exit 0
    ;;
esac
#
# Begin real processing
#
NAME=dropbear
PROG=/sbin/dropbear
# get all server pids that should be ignored
ignore=""
for server in \`cat /var/run/\${NAME}*.pid\`
do
    ignore="\${ignore} \${server}"
done
# get all running pids and kill client connections
for pid in \`pidof "\${NAME}"\`
do
    # check if correct program, otherwise process next pid
    grep -F -q -e "\${PROG}" "/proc/\${pid}/cmdline" || {
        continue
    }
    # check if pid should be ignored (servers)
    skip=0
    for server in \${ignore}
    do
        if [ "\${pid}" == "\${server}" ]
        then
            skip=1
            break
        fi
    done
    [ "\${skip}" -ne 0 ] && continue
    # kill process
    echo "\$0: Killing \${pid}..."
    kill \${pid}
done
EOF
chmod +x /etc/initramfs-tools/scripts/local-bottom/kill_dropbear_connections

cat << DONE > /etc/initramfs-tools/hooks/crypt_unlock.sh
#!/bin/sh
 
PREREQ="dropbear"
 
prereqs() {
    echo "\$PREREQ"
}
 
case "\$1" in
    prereqs)
        prereqs
        exit 0
    ;;
esac
 
. "\${CONFDIR}/initramfs.conf"
. /usr/share/initramfs-tools/hook-functions
 
if [ "\${DROPBEAR}" != "n" ] && [ -r "/etc/crypttab" ] ; then
    #run unlock on ssh login
    echo unlock>>"\${DESTDIR}/etc/profile"
	#write the unlock script
    cat > "\${DESTDIR}/bin/unlock" << EOF
#!/bin/sh

# Read passphrase
read_pass()
{
    # Disable echo.
    stty -echo

    # Set up trap to ensure echo is enabled before exiting if the script
    # is terminated while echo is disabled.
    trap 'stty echo' EXIT SIGINT

    # Read passphrase.
    read "\\\$@"

    # Enable echo.
    stty echo
    trap - EXIT SIGINT

    # Print a newline because the newline entered by the user after
    # entering the passcode is not echoed. This ensures that the
    # next line of output begins at a new line.
    echo
}

printf "Enter passphrase: "
read_pass password
echo "\\\$password" >/lib/cryptsetup/passfifo 

EOF
 
    chmod +x "\${DESTDIR}/bin/unlock"

    echo On successful unlock this ssh-session will disconnect. >> \${DESTDIR}/etc/motd
    echo Run \"unlock\" to get passphrase prompt back if you end up in the shell. >> \${DESTDIR}/etc/motd
fi
DONE
chmod +x /etc/initramfs-tools/hooks/crypt_unlock.sh


update-initramfs -u -k $(uname -r)

echo "************************************************************************"
echo "DONE!"
echo 
echo "Copy /etc/initramfs-tools/root/.ssh/id_rsa to your local machine."
echo "This is the private key you need to log into dropbear (no password, root@machinename)."
echo "A better option is to add your own public key to /etc/initramfs-tools/root/.ssh/authorized_keys and rerun update-initramfs -u -k \`uname -r\`"
echo 
echo "Make sure you have a safe boot option before rebooting."
echo "************************************************************************"
