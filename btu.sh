#!/bin/bash
#-----------------------------------------
#NAME/COMMAND: backthisup / btu
#-----------------------------------------
#SETTINGS
#-----------------------------------------
#SERVER SETTINGS
proto_ssh="blowfish";
proto_ft="arcfour"; #rc4 insecure, find alternative streaming cypher
#server
serveraddr="192.168.1.2";
serverunm="arch";
serverbkppath="/media/xt1/BackThisUp"; #backup container in server
#ssh/sftp id server
server=$serverunm"@"$serveraddr;
logfile="/tmp/btulogs.txt"

#CLIENT SETTINGS
#set device
thisdevice="laptop";
#define devices here
case $thisdevice in
'desktop')
	deviceaddr="192.168.1.2";
	deviceunm="arch";
	bkppathdevice="/devices/desktop"; #backup path in server container
	devicebkppath="/home/BackThisUp"; #backup path on device
;;
'laptop')
	deviceaddr="192.168.1.9";
	deviceunm="mint16";
	bkppathdevice="/devices/xps15"; #backup path in server container
	devicebkppath="/home/BackThisUp"; #backup path on device
;;
's2')
	deviceaddr="192.168.1.4";
	deviceunm="";
	bkppathdevice="/devices/s2"; #backup path in server container
	devicebkppath="/storage"; #backup path on device
;;
esac
#-----------------------------------------
#FUNCTIONS
#-----------------------------------------
#path modification/ escaping characters
fn_escape(){ #escaping special characters \b, \(, \), \!, \& 
	echo `echo $* | sed 's/ \+/\\\ /g'| sed 's/(\+/\\\(/g'| sed 's/)\+/\\\)/g'| sed 's/!\+/\\\!/g'| sed 's/&\+/\\\&/g'`;
}
fn_getpath(){ #reading/fixing paths from user input
	case "$1" in 
		''|'.'|'./') #pwd
			src=`readlink -f $PWD;`;
		;;
		*) #path given
			fullpath=`fn_argclean "$1";`
			#echo $fullpath;
			src=`readlink -f "$fullpath"`;
		;;
		esac
	echo "$src";
}
fn_getspath(){ #replaces device path with server paths
	echo `echo $* | sed 's_'"$devicebkppath"'_'"$serverbkppath$bkppathdevice"'_g'`;
}
fn_getdpath(){ #replaces server paths with device paths
	echo `echo $* | sed 's_'"$serverbkppath$bkppathdevice"'_'"$devicebkppath"'_g'`;
}
#remote execution
fn_sexec(){ #execute commands in server remotely
	ssh -c "$proto_ssh" "$server" "$@";
}
#shortcuts in arguments
fn_argclean(){ #replaces :shortcuts with their original values
	#echo $*;
	#replace-rules here
	# /dbackup = $devicebkppath e.g laptop = /home/BackThisUp
	arglist=`echo $* | sed 's_'/dbackup'_'$devicebkppath'_g'`;
	# /sbackup = $serverbkppath + $bkppathdevice e.g /media/xt1/BackThisUp + /devices/xps15
	arglist=`echo $arglist | sed 's_'/sbackup'_'$serverbkppath$bkppathdevice'_g'`;
	echo $arglist;
}
#parsing arguments
fn_argparse(){
	arglist="$@";
	for item in $arglist;
	do
		case "$item" in 
		--*| -*) 
			if [ "$string" != "" ];
			then
				string="$string\n$item"; #argument
			else
				string="$item";
			fi
		;;
		*) string="$string `fn_escape "$item"`"; #value
		;;
		esac;
	done;
	echo "$string";
}
#shift
#fn_shift(){
#	if [ $# -ge 1 ];
#	then shift;
#	else exit;
#	fi
#}
#main file transfer fn here
fn_transfer(){
	scp -r -c "$proto_ft" "$1" "$2";
}
#logging
fn_slog(){
	logline="$*";
	fn_sexec "echo $logline >> $logfile"
}
#help
fn_showhelp(){
	echo "----------------\nBackThisUp by DaWwG\n----------------
INFO:
DEVICE:$thisdevice($deviceunm@$deviceaddr)
SERVER: $serverunm@$serveraddr
Backup path on device: $devicebkppath <--- /dbackup
Backup path on server: $serverbkppath$bkppathdevice <--- /sbackup
if running first time, then run $ btu -gen to setup keypairs.

USAGE:
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
----------------\nEnjoy :)\n----------------";
	exit;
}
#-----------------------------------------
#Run
#-----------------------------------------
#if run at server. print message and exit
if [ "$deviceaddr" = "$serveraddr" ];
then 
	echo "Device and server are the same machine. Copy your shit yourself.";
	exit;
fi
#help options
if [ $# = 0 ];
then 
	echo "No options specified.\n`fn_showhelp`";
	exit;
fi
#argparse
#fn_argparse "$@";
#exit;

#-----------------------------------------
#Argument Parsing
#-----------------------------------------
while test ${#} -gt 0; #keep eating arguments till die :)
do
	case "$1" in
#check if server is live ++ if ip given, ping that ip instead.
	'--checkalive'|'-cl')
		shift;
		case "$1" in
		$serveraddr| '') #if none or server ip
			echo "Pinging Server at $serveraddr"
			ping -c 3 $serveraddr;
		;;
		*\.*\.*\.*) #for any other ip
			ping -c 3 "$1";
		;;
		*\.*\.*) #for url passes anything.anything.anything
			ping -c 3 "$1";
		;;
		*) #default
			echo "Usage: btu -cl <ip> | default ip: $serveraddr(server)";
			exit;
		;;
		esac
	;;
#generating keypair for public key authorization between client/server #no password YAY! 
#needs PasswordAuthentication yes in /etc/ssh/sshd.conf
	'--genkeypair'|'-g')
		shift;
		ssh-keygen -t rsa -N '' -f "/home/$USER/.ssh/id_rsa";
		fn_transfer "/home/$USER/.ssh/id_rsa.pub" "$server:/tmp/";
		fn_sexec 'cat /tmp/id_rsa.pub >> /home/$USER/.ssh/authorized_keys;'; # chmod 700 /home/$USER/.ssh; chmod 600 /home/$USER/.ssh/authorized_keys;';
		echo "Try logout/login if agent fails to sign with the credentials."
	;;
#ssh
	'--ssh'|'-ssh')	
		shift;
		sship=$serverunm"@"$serveraddr; #defaults to server
		sshcomm=""
		case "$1" in
		$serveraddr| '') #if none or server ip
			echo "Conecting to server at $serveraddr as $serverunm";
			sshcomm=$@;
		;;
		*@*\.*\.*\.*) #for any other user@ip
			sship=$1;
			sshcomm=$@;
		;;
		*@*\.*\.*) #for any other user@url
			sship=$1;
			sshcomm=$@;
		;;
		*) #default
			echo "Usage: btu -ssh <userip> <command> | default user@ip: $serverunm@$serveraddr(server)";
			return;
		esac
		#echo $sship"|"$sshcomm;
		ssh -c "$proto_ssh" "$sship" "$sshcomm";
		return;
	;;
#upload files
	'--up'|'-u')
		shift;
		src=`fn_argclean $1`;
		shift;
		dst=`fn_argclean $1`;
		echo "src=$src\ndst=$dst";
		fn_transfer "$src" "$server:$dst";
		return;
	;;
#download files
	'--down'|'-d') 
		shift;
		src=`fn_argclean $1`;
		shift;
		dst=`fn_argclean $1`;
		echo "src=$src\ndst=$dst";
		fn_transfer "$server:$src" "$dst";
		return;
	;;
#view remote files
	'--list'|'-ls') 
		shift;
		src="";
		dst="";
		src=`fn_getpath "$1"`;
		dst=`fn_getspath $src`;
		echo "src=$src\ndst=$dst\n\nContents:\n---------"
		fn_sexec "ls -A $dst";
	;;
#download files remotely in server #eats all bandwidth
	'--wget'|'-dw')
		shift;
		echo "src=$1\ndst=$2";
		fn_sexec "cd $2;wget -bvc -nc '$1';";
	;;
#upload & replace file structure at given filepath else $PWD
	'--push'|'-p')
		shift;
		src=`fn_getpath "$1"`;
		#if file/dir exists in backup, replace $bkppathdevice with $devicebkppath and transfer else error
		dst=`fn_getspath "$src"`;
		#echo "src=$src\ndst=$dst"; #show src and dst
		#basic push service - replace ALL previous content in server with current content from device
		if [ -f "$src" ];
		then 
			echo "Deleting file $dst"
			fn_sexec "rm -f `fn_escape $dst`"; #remote paths needs escaping
			echo "Copying file(s)..."
			echo "src=$src\ndst=$dst"; #show src and dst
			scp -c "$proto_ft" "$src" "`fn_escape $server:$dst`"; #destination needs escaping
		elif [ -d "$src" ];
		then 
			echo "Deleting directory $dst";
			fn_sexec "rm -rf --preserve-root $dst/*"; #save that directory in case its a shortlink
			echo "Copying file(s)..."
			echo "src=$src\ndst=${dst%/*}"; #show src and dst #remove the last dirname otherwise path becomes dir/dir
			scp -r -c "$proto_ft" "$src" "$server:${dst%/*}";
		fi
		#find "$src" | sort > /tmp/dfiles; #finding files in device
		#ssh -c $proto_ssh $server "find $dst | sort" > /tmp/sfiles; #finding files in server
		#dpath>spath in dfiles
		#fn_getspath `cat /tmp/dfiles` > /tmp/dfiles_slocation; #converting dpaths to spaths for checking
		#touch /tmp/dfiles_slocation;
		#for line in `cat /tmp/dfiles`;
		#do
		#	echo "line="$line;
		#	echo "converted="`fn_getspath "$line";`;
		#	echo `fn_getspath "$line";` >> /tmp/dfiles_slocation;
		#done;
		#cat /tmp/dfiles;
		#cat /tmp/sfiles;
		#cat /tmp/dfiles_slocation;
		#for line in $dfiles_slocation;
		#do
			#if line in 
		#rm /tmp/dfiles_slocation;
	;;
#download & replace file structure at given filepath else $PWD
	'--pull'|'-l') 
		shift;
		src="";
		dst=`fn_getpath "$1"`;
		#if file/dir exists in device, replace $devicebkppath with $bkppathdevice and transfer else error
		src=`fn_getspath "$dst"`;
		#echo "src=$src\ndst=$dst"; #show src and dst
		#basic pull service - replace ALL current content in device with old content in server
		#if file/dir exists in backup, replace $bkppathdevice with $devicebkppath and transfer else error
		if [ -f "$dst" ];
		then 
			echo "Deleting file $dst"
			rm -f "$dst";  
			echo "Copying file(s)..."
			echo "src=$src\ndst=$dst"; #show src and dst
			scp -c "$proto_ft" "`fn_escape $server:$src`" "$dst"; #destination needs escaping
		elif [ -d "$dst" ];
		then 
			echo "Deleting directory $dst";
			rm -rf --preserve-root "$dst/*"; #save that directory in case its a shortlink
			echo "Copying file(s)..."
			echo "src=$src\ndst=${dst%/*}"; #show src and dst #remove the last dirname otherwise path becomes dir/dir
			scp -r -c "$proto_ft" "`fn_escape $server:$src`" "${dst%/*}";
		fi
	;;
	'--syncup'|'-su')
		shift;
		src=`fn_getpath "$1"`;
		filelist="";
		files=`find "$src";`
		echo $files
		#for item in $files
		#do 
		#	#
		#done;
		for item in $filelist
		do echo $item 
		done
	;;
	'--help'|'-h') #show help
		fn_showhelp;
		shift;
	;;
	*) #no-arg, show options & exit #unused
		echo "Argument invalid.\nYou Entered:\n$1\n`fn_showhelp`"
		shift;
	;;
	esac
done;
