#backthisup [btu]

easy data transfer from/to desktop/server and other devices initiated by the latter. 
[ the server can't and shouldn't do shit by itself.]
currently using scp so openssh needed..might setup ftps later..

###TODO
	sync=upload only delta files| getarc=create the folder structure.LOOKUP: rsync algorithm
	
	setup repo verison management + git cloning if worth reading the api in bash / else write api-spec in py
	
	device management> add/remove device, setting different filepaths..

	write & link btuserver.sh
	
####Usage:
	#check if server/any other ip is pingable
	$ btu --checkalive | -cl <ip>
	
	ssh (default to server)
	$ btu --ssh | -ssh <user@ip> '<command>'
	
	downloading files
	$ btu --down | -d /srcpath /destpath
	
	uploading files
	$ btu --up | -u /srcpath /destpath
	
	download files remotely in server
	$ btu --wget | -g /srcpath /dstpath
	
	remote list files
	$ btu --list | -ls /srcpath
	
	replace all files in srcpath or PWD in device, with files at the same place in server, for backup only.
	$ btu --pull | -l /srcpath
	
	replace all files in srcpath or PWD in server, with files from device, for backup only.
	$ btu --push | -p /srcpath
	
	help
	$ btu --help | -h help

for normal file transfer use backthisup -<up/down> /src/ /dst/
for transferring files from backup, navigate to proper folder, use backthisup -<push/pull>
other mods= easy ssh, ls, sync

devices=desktop, laptop, s2, m9, rpi

####Hardware Upgrade
divide storage in two parts..
	stage=files that are updated and read frequently..1TB drive=/media/xt2 
		[UPGRADE: >1TB hybrid drive]??
	glacier=files that are updated in large chunks as archival, and rarely read...4TB drive=/media/xt1 
		[UPGRADE: 16TB(4x4) NAS 7200rpm btrfs RAID10]
