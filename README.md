backthisup [btu]
================

easy data transfer from/to desktop/server and other devices initiated by the latter. 
[ the server can't and shouldn't do shit by itself.]
currently using scp so openssh needed..might setup ftps later..

for normal file transfer use backthisup -<up/down> /src/ /dst/
for transferring files from backup, navigate to proper folder, use backthisup -<push/pull>
other mods= easy ssh, ls, sync

devices=desktop, laptop, s2, m9, rpi

divide storage in two parts..
	stage=files that are updated and read frequently..1TB drive=/media/xt2 
		[UPGRADE: >1TB hybrid drive]
	glacier=files that are updated in large chunks as archival, and rarely read...4TB drive=/media/xt1 
		[UPGRADE: 12TB(4x3) NAS 7200rpm btrfs RAID10]

TODO=sync=upload only delta files| getarc=create the folder structure.LOOKUP: rsync algorithm
TODO=setup repo verison management + git cloning if worth reading the api in bash / else write api-spec in py
TODO=device manageent> add/remove device, setting different filepaths..
TODO=write & link btuserver.sh
