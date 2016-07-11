# LUKS-unlock-by-usb-ssh-passphrase
a hook-script for ubuntu 14.04 to unlock a LUKS-drive at boot, using ssh, an usb-drive or passphrase
This script is based on the LUKS-tripple-unlock script (https://github.com/chadoe/luks-triple-unlock) by Martin van Beurden, and on the tutorial
Entschlüsseln mit einem USB-Stick (https://wiki.ubuntuusers.de/System_verschl%C3%BCsseln/Entschl%C3%BCsseln_mit_einem_USB-Schl%C3%BCssel/ ),
Revision from 14. Juni 2016 08:32 last edited by noisefloor.
All credits and rights for these scripts belong to them.
I made this script beecause I used an usb-drive to unlock my server. Because i wanted to be able to remotely reboot the server if necessary,
I had to let the usb-drive plugged into the server, which makes any encryption more or less useless. Because of that I began searching
for other ways to unlock the serverand found the script i metnioned above, which was very similar to the script I already used for unlocking.
After having read both of them it was clear they have got the same roots, so I thought it schould be possible to combine them, which is 
exactly what I did.

This Script was tested on Ubuntu Server 14.04. I am not responsible for any changes you make to your system. Continue with caution and ensure
to have an initramfs-backup you can use to boot if something strange happens.
The script works for me when having one LVM to unlock. This script also works with RAID 1.

This script uses dropbear. For detailed instructions how to set up dropbear, please use the following article: 
https://www.thomas-krenn.com/de/wiki/Voll-verschl%C3%BCsseltes-System_via_SSH_freischalten

How to install this file:
- get both of the scripts to your server using git clone.
- run the install.sh installation script.
- If you want to add the possibility, to login to dropbear using key-files, please do this now and after that "update-initramfs -c -k 'uname -r'"

How to use this file:
- Using the passphrase:
You can just type in the passphrase using a keyboard connected to the server.
- Using SSH:
After loging in to the server, you get asked for the passphrase. If you enter it correctly, the device will be unlockend.
- Using an usb-drive:
Using this method, you create a key-file on your usb-drive, but instead of just creating a normal file, it will write the key at the beginning
of the drive. So there is nothing blowing up your cover for your encrypted harddrive.
