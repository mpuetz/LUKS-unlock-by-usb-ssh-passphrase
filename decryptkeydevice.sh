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

# set DEBUG=$TRUE to display debug messages, DEBUG=$FALSE to be quiet
DEBUG=$TRUE

PLYMOUTH=$FALSE
# test for plymouth and if plymouth is running
if [ -x /bin/plymouth ] && plymouth --ping; then
        PLYMOUTH=$TRUE
fi

# is usplash available? default false
USPLASH=$FALSE
# test for outfifo from Ubuntu Hardy cryptroot script, the second test
# alone proves not completely reliable.
if [ -p /dev/.initramfs/usplash_outfifo -a -x /sbin/usplash_write ]; then
    # use innocuous command to determine if usplash is running
    # usplash_write will return exit-code 1 if usplash isn't running
    # need to set a flag to tell usplash_write to report no usplash
    FAIL_NO_USPLASH=1
    # enable verbose messages (required to display messages if kernel boot option "quiet" is enabled
    /sbin/usplash_write "VERBOSE on"
    if [ $? -eq $TRUE ]; then
        # usplash is running
        USPLASH=$TRUE
        /sbin/usplash_write "CLEAR"
    fi
fi

# is stty available? default false
STTY=$FALSE
STTYCMD=false
# check for stty executable
if [ -x /bin/stty ]; then
	STTY=$TRUE
	STTYCMD=/bin/stty
elif [ `(busybox stty >/dev/null 2>&1; echo $?)` -eq 0 ]; then
	STTY=$TRUE
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
	if [ $# -gt 0 ]; then
		# handle multi-line messages
		echo $2 | while read LINE; do
			if [ $PLYMOUTH -eq $TRUE ]; then
				/bin/plymouth message --text="$1 $LINE"
			elif [ $USPLASH -eq $TRUE ]; then
                		# use usplash
				/sbin/usplash_write "$1 $LINE"
			else
				# use stderr for all messages
				echo $3 "$2" >&2
			fi
		done
	fi
}

dbg ()
{
	if [ $DEBUG -eq $TRUE ]; then
		msg "$@"
	fi
}

plymouth_readpass ()
{
    local PASS PLPID
    local PIPE=/lib/cryptsetup/passfifo
    mkfifo -m 0600 $PIPE
    plymouth ask-for-password --prompt "$1"  >$PIPE &PLPID=$!
    read PASS <$PIPE
    kill $PLPID >/dev/null 2>&1
    rm -f $PIPE
    echo "$PASS"
}

# read password from console or with plymouth
# usage: readpass "prompt"
readpass ()
{
	if [ $# -gt 0 ]; then
		if [ $PLYMOUTH -eq $TRUE ]; then
			PASS=$(plymouth_readpass "$1")
		elif [ $USPLASH -eq $TRUE ]; then
            		msg TEXT "WARNING No SSH unlock support available"
			usplash_write "INPUTQUIET $1"
            		PASS="$(cat /dev/.initramfs/usplash_outfifo)"
        	elif [ -f /lib/cryptsetup/askpass ]; then
			PASS=$(/lib/cryptsetup/askpass "$1")
		else
			msg TEXT "WARNING No SSH unlock support available"
			[ $STTY -ne $TRUE ] && msg "WARNING stty not found, password will be visible"
			echo -n "$1" >&2
			$STTYCMD -echo
			read -r PASS </dev/console >/dev/null
			[ $STTY -eq $TRUE ] && echo >&2
			$STTYCMD echo
		fi
	fi
	echo -n "$PASS"
}

# flag tracking key-file availability
OPENED=$FALSE

# decryptkeydevice configured so try to find a key
if [ ! -z "$DECRYPTKEYDEVICE_DISKID" ]; then
	msg "Checking devices for decryption key ..."
	# Is the USB driver loaded?
	cat /proc/modules | busybox grep usb_storage >/dev/null 2>&1
	USBLOAD=0$?
	if [ $USBLOAD -gt 0 ]; then
		dbg "Loading driver 'usb_storage'"
		modprobe usb_storage >/dev/null 2>&1
	fi
	# Is the mmc_block driver loaded?
#	cat /proc/modules | busybox grep mmc >/dev/null 2>&1
#	MMCLOAD=0$?
#	if [ $MMCLOAD -gt 0 ]; then
#		dbg "Loading drivers for 'mmc'"
#		modprobe mmc_core >/dev/null 2>&1
#		modprobe ricoh_mmc >/dev/null 2>&1
#		modprobe mmc_block >/dev/null 2>&1
#		modprobe sdhci >/dev/null 2>&1
#	fi

	# give the system time to settle and open the devices
	sleep 5

	for DECRYPTKEYDEVICE_ID in $DECRYPTKEYDEVICE_DISKID ; do
		DECRYPTKEYDEVICE_FILE="/dev/disk/by-id/$DECRYPTKEYDEVICE_ID"
		dbg "Trying disk/by-id/$DECRYPTKEYDEVICE_FILE ..."
		if [ -e $DECRYPTKEYDEVICE_FILE ] ; then
			dbg " found disk/by-id/$DECRYPTKEYDEVICE_FILE ..."
			OPENED=$TRUE
			break
		fi
		$DECRYPTKEYDEVICE_FILE=""
	done
fi

# clear existing usplash text and status messages
[ $USPLASH -eq $TRUE ] && msg STATUS "                               " && msg CLEAR ""

if [ $OPENED -eq $TRUE ]; then
	/bin/dd if=$DECRYPTKEYDEVICE_FILE bs=$DECRYPTKEYDEVICE_BLOCKSIZE skip=$DECRYPTKEYDEVICE_SKIPBLOCKS count=$DECRYPTKEYDEVICE_READBLOCKS 2>/dev/null
	if [ $? -eq 0 ] ; then
		dbg "Reading key from '$DECRYPTKEYDEVICE_FILE' ..."
	else
		dbg "FAILED Reading key from '$DECRYPTKEYDEVICE_FILE' ..."
		OPENED=$FALSE
	fi
fi

if [ $OPENED -ne $TRUE ]; then
	msg "FAILED to find suitable Key device. Plug in now and press enter, or"
	readpass "Enter passphrase: "
	msg " "
else
	msg "Success loading key from '$DECRYPTKEYDEVICE_FILE'"
fi

[ $USPLASH -eq $TRUE ] && /sbin/usplash_write "VERBOSE default"
