#!/bin/bash
#-----------------------------------------
#NAME/COMMAND: backthisup / btu
#-----------------------------------------
#SETTINGS
#-----------------------------------------
#SERVER SETTINGS
proto_ssh="blowfish";
proto_ft="arcfour"; #rc4 insecure, find alternative streaming cypher

#log
slogfile="/tmp/btulogs";

#server -> machine connected to storage
serveraddr="192.168.1.2";
serverunm="arch";
serverbkppath="/media/xt1/BackThisUp"; #backup container in server
#ssh/sftp server
server=$serverunm"@"$serveraddr;

#CLIENT SETTINGS
#set device
thisdevice='LAPTOP';
#define devices here
case $thisdevice in
'DESKTOP')
	deviceaddr="192.168.1.2";
	deviceunm="arch";
	bkppathdevice="/devices/desktop"; #backup path in server container
	devicebkppath="/home/BackThisUp"; #backup path on device
;;
'LAPTOP')
	deviceaddr="192.168.1.3";
	deviceunm="mint16";
	bkppathdevice="/devices/xps15"; #backup path in server container
	devicebkppath="/home/arch"; #backup path on device
;;
'GALAXYS2')
	deviceaddr="192.168.1.4";
	deviceunm="";
	bkppathdevice="/devices/s2"; #backup path in server container
	devicebkppath="/storage"; #backup path on device
;;
'RASPBERRYPI')
	deviceaddr="192.168.1.5";
	deviceunm="pi";
	bkppathdevice="/devices/rpi"; #backup path in server container
	devicebkppath="/home/BackThisUp"; #backup path on device
;;
'PIPOM9')
	deviceaddr="192.168.1.6";
	deviceunm="";
	bkppathdevice="/devices/m9"; #backup path in server container
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
	echo "$string" > "/tmp/btu_args";
	cat "/tmp/btu_args";
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
	fn_slog "TFR_$1_$2";
	scp -r -c "$proto_ft" "$1" "$2";
}
#logging @ server
fn_slog(){
	logline="$*";
	fn_sexec "echo `date -Ins`_$logline >> $logfile"
}
fn_showlog(){
	fn_sexec "cat $logfile | tail";
}
#file exists test
fn_existsindevice(){
	echo `test -e "$1" && echo True || echo ''`;
}
fn_existsinserver(){
	#echo `fn_sexec "test -e \"$1\" && echo True || echo False"`;
	`fn_sexec "test -e \"$1\" && echo True || echo '' "`;
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
if [ ${#} = 0 ];
then 
	fn_slog "NO-OPS"
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
#check if server / other machine is live
	'--checkalive'|'-cl')
		shift;
		case "$1" in
		$serveraddr| '') #if none or server ip
			uip=$serveraddr;
		;;
		*\.*\.*\.*) #for any other ip
			uip="$1";
		;;
		*\.*\.*) #for url passes anything.anything.anything
			uip="$1";
		;;
		*) #default
			echo "Usage: btu -cl <ip> | default ip: $serveraddr(server)";
			exit;
		;;
		esac
		echo "Pinging Server at $serveraddr"
		fn_slog "PING_$uip";
		ping -c 3 "$uip" 2>fn_slog;
	;;
#generating keypair for public key authorization between client/server #no password YAY! 
#needs PasswordAuthentication yes in /etc/ssh/sshd.conf #ENABLE before / DISABLE after setting up keypairs
	'--genkeypair'|'-g')
		shift;
		fn_slog "START_SSH_KEYGEN"
		ssh-keygen -t rsa -N '' -f "/home/$USER/.ssh/id_rsa";
		fn_transfer "/home/$USER/.ssh/id_rsa.pub" "$server:/tmp/pubkey";
		fn_sexec 'cat /tmp/pubkey >> /home/$USER/.ssh/authorized_keys;'; # chmod 700 /home/$USER/.ssh; chmod 600 /home/$USER/.ssh/authorized_keys;';
		fn_slog "KEY_EXCHANGE_SUCCESS"
		echo "Try logout/login if agent fails to sign with the credentials."
	;;
#ssh to server/other linux
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
		fn_slog "BEGIN_SSH_SESSION_$sship"
		ssh -c "$proto_ssh" "$sship" "$sshcomm" 2>fn_slog;
		fn_slog "END_SSH_SESSION_$sship"
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
	;;
#download & replace file structure at given filepath else $PWD
	'--pull'|'-l') 
		shift;
		src="";
		dst=`fn_getpath "$1"`;
		#if file/dir exists in device, replace $devicebkppath with $bkppathdevice and transfer else error
		src=`fn_getspath "$dst"`;
		#echo "src=$src\ndst=$dst"; #show src and dst
		#basic pull service - replace ALL current content in device with last backup in server
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
			rm -rf --preserve-root "$dst/*"; #lel
			echo "Copying file(s)..."
			echo "src=$src\ndst=${dst%/*}"; #show src and dst #remove the last dirname otherwise path becomes dir/dir
			scp -r -c "$proto_ft" "`fn_escape $server:$src`" "${dst%/*}";
		fi
	;;
	'--syncup'|'-su') #direcctory sync, upload files that dont exist in server
		shift;
		src=`fn_getpath "$1"`;
		find "$src"|sort > "/tmp/btu_su_filelist";
		while read line;
		do
			dst=`fn_getspath "$line"`;
			echo "src=$line\ndst=$dst"; #show src and dst
			if [ -f "$src" ];
			then
				if [ `fn_existsinserver "$dst"` ];
				then
					echo "File exists.";
				else
					echo "File not found."
				fi
			elif [ -d "$src" ];
			then 
				if [ `fn_existsinserver "$dst"` ];
				then
					echo "Dir exists.";
				else
					echo "Dir not found."
				fi
			fi
		done < "/tmp/btu_su_filelist"
		shift;
	;;
	'--help'|'-h') #show help
		fn_showhelp;
		shift;
	;;
	'--log') #show recent logs
		fn_showlog;
		shift;
	;;
	*) #no-arg, show options & exit #unused
		echo "Argument invalid.\nYou Entered:\n$1\n`fn_showhelp`"
		shift;
	;;
	esac
done;
