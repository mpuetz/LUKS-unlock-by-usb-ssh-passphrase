#! /bin/bash

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
ifaces=\$(ip addr|egrep "^[0-9]*: "|egrep -v "^[0-9]*: lo:"|awk '{print \$2}'|sed 's/:$//g')
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
    echo "\$0: Killing ${pid}..."
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
#! /bin/bash

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
ifaces=\$(ip addr|egrep "^[0-9]*: "|egrep -v "^[0-9]*: lo:"|awk '{print \$2}'|sed 's/:$//g')
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
    echo "\$0: Killing ${pid}..."
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
