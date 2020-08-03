# LUKS-unlock-by-usb-ssh-passphrase
a hook-script for ubuntu server 14.04 to unlock a LUKS-drive at boot, using ssh, an usb-drive or passphrase

        CAUTION! Usage of this file happens on your own risk!

This script has been tested on fresh installations/upgrades of ubuntu server 14.04 and 16.04. Unfortunately I don't have the opportunity to test it more in depth.

This script is based on the LUKS-tripple-unlock script (https://github.com/chadoe/luks-triple-unlock) by Martin van Beurden, 

on the tutorial Entschlüsseln mit einem USB-Stick (https://wiki.ubuntuusers.de/System_verschl%C3%BCsseln/Entschl%C3%BCsseln_mit_einem_USB-Schl%C3%BCssel/ ),
Revision from 14. Juni 2016 08:32 last edited by noisefloor and originally created by Franco_bez (https://ubuntuusers.de/user/franco_bez/)

and decryptkeydevice by Franco_bez (https://ubuntuusers.de/user/franco_bez/) as found at (https://wiki.ubuntuusers.de/System_verschl%C3%BCsseln/Entschl%C3%BCsseln_mit_einem_USB-Schl%C3%BCssel/#Anlegen-der-noetigen-Konfigurationsdateien), published under CC BY-NC-SA 2.0 DE (http://creativecommons.org/licenses/by-nc-sa/2.0/de/deed.de).

All credits and rights for these scripts belong to them.

I made this script because I used an usb-drive to unlock my server. Wanting to be able to remotely reboot the server if necessary,
I had to let the usb-drive plugged into the server, which makes any encryption more or less useless. Because of that I began searching
for other ways to unlock the server and found the script i mentioned above, which was very similar to the script I already used for unlocking.
After having read both of them it was clear they have got the same roots, so I thought it should be possible to combine them, which is
exactly what I did.


This Script was tested on Ubuntu Server 14.04 and 16.04. I am not responsible for any changes you make to your system. Continue with caution and ensure to have an initramfs-backup you can use to boot if something strange happens.

The script works for me when having one LVM to unlock. This script also works with RAID 1.

This script uses dropbear. For detailed instructions how to set up dropbear, please use the following article: 
https://www.thomas-krenn.com/de/wiki/Voll-verschl%C3%BCsseltes-System_via_SSH_freischalten

How to install this file:
- connect the usb-drive to the machine
- on your machine (or via ssh) run "sudo ls -l /dev/disk/by-id" and watch out for your usb-drive.
- Write down the id of your usb-drive (usb-XXXX-0:0) and the label (../../sdX  WITHOUT any partiton number (NOT sdX1))
- run "sudo fdisk -l /dev/sdX" and replace sdX with the label you have written down before. Write down the blocksize (like 512 bytes), you just need the number! Please also write down the beginning of the first partition (sdX1).
- write down the label of the encrypted partition. If you don't know which device this partition is on, run 'sudo fdisk -l | grep "*"'. This will show you the boot-partiton. Because you are using a script to unlock your machine while booting this will mostly get the right device. Please write the label down WITHOUT any partition-numbers (just /dev/sdX). 
- get both of the scripts to your server using "wget https://codeload.github.com/mpuetz/LUKS-unlock-by-usb-ssh-passphrase/legacy.zip/master && unzip master && cd mpuetz-* && sudo chmod +x install.sh".
- run the install.sh installation script.
- If you want to add the possibility, to login to dropbear using key-files, please do this now and after that run "sudo update-initramfs -c -k 'uname -r'"

How to use this file:
- Using the passphrase:
You can just type in the passphrase using a keyboard connected to the server.
- Using SSH:
After loging in to the server, you get asked for the passphrase. If you enter it correctly, the device will be unlockend.
- Using an usb-drive:
Using this method, you create a key-file on your usb-drive, but instead of just creating a normal file, it will write the key at the beginning
of the drive. So there is nothing blowing up your cover for your encrypted harddrive.

One last word concerning the License:
unfortunately, here are two projects merged which are published under different Licenses. The install.sh-script from Martin van Beurden
may be used under the MIT-License, whereas the script from Franco_be which is found at ubuntuusers.de has to be published under the 
CC BY-NC-SA 2.0 DE by the forum-guidelines from ubuntuusers.de.
So its a bit unclear which License to use. Because the MIT-License is pretty easy, whereas the CC-License is pretty restrictive it 
seems to be the most logical decission to use this License for the scripts. I hope this is okay with everyone who contributed to the 
scripts I used. If it is not, please feel free to contact me so we can decide how to go on.
