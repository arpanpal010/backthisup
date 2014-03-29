#backthisup [btu]
================

easy data transfer from/to desktop/server and other devices initiated by the latter. 
[ the server can't and shouldn't do shit by itself.]
currently using scp so openssh needed..might setup ftps later..

##Usage:
$ btu --checkalive | -cl <ip> --> check if server/any other ip is pingable
$ btu --ssh | -ssh <user@ip> '<command>' --> ssh default to server
$ btu --down | -d /srcpath /destpath --> downloading files
$ btu --up | -u /srcpath /destpath --> uploading files
$ btu --wget | -g /srcpath /dstpath --> download files remotely in server
$ btu --list | -ls /srcpath -->remote view files
$ btu --pull | -l /srcpath --> replace all files in srcpath or PWD in device, with files at the same place in server 	#for backup only.
$ btu --push | -p /srcpath --> replace all files in srcpath or PWD in server, with files from device 	#for backup only.
$ btu --help | -h help
#$ btu -syncup /srcpath 		#for backup only.

for normal file transfer use backthisup -<up/down> /src/ /dst/
for transferring files from backup, navigate to proper folder, use backthisup -<push/pull>
other mods= easy ssh, ls, sync

devices=desktop, laptop, s2, m9, rpi

TODO=sync=upload only delta files| getarc=create the folder structure.LOOKUP: rsync algorithm
TODO=setup repo verison management + git cloning if worth reading the api in bash / else write api-spec in py
TODO=device manageent> add/remove device, setting different filepaths..
TODO=write & link btuserver.sh

####Upgrade
divide storage in two parts..
	stage=files that are updated and read frequently..1TB drive=/media/xt2 
		[UPGRADE: >1TB hybrid drive]??
	glacier=files that are updated in large chunks as archival, and rarely read...4TB drive=/media/xt1 
		[UPGRADE: 16TB(4x4) NAS 7200rpm btrfs RAID10]
