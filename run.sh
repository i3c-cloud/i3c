#!/bin/bash

if [ "$1" != "secret" ]; then
echo "=================================================================="
echo " i3c.Cloud $i3cVersion  $I3C_CNAME:${I3C_HOME}/run.sh"
#echo " On $(lsb_release -a | grep Description:)"
echo "=================================================================="
fi

#one command for all
alias i-apk='/r install';

case "$1" in
	secret)
		cat /run/secrets/$2;
		;;
	#install entrypoint in container	
	entrypoint)
		if [ -e $2 ]; then
			chmod a+x $2
			if [ -e /r ]; then
				rm -f /r 
			fi 
			ln -s $2 /r
		else
			echo "ERROR: file not found: $2";
		fi	 	
		;;			
	startup)
		while true; do
			sleep 1000
		done
		;;
	echo)
		echo "Echo from /run.sh: ${@:2}"
		;;
	untar)
		tar -xvzf "${@:2}"
		;;	
	apt)
		echo "==================!!!!!!!!!!!!!!!!!!======================================="
		echo "[ i3c/run.sh ]$1 unhandled - add to Your local /run-xxx implementation"
		echo "==================!!!!!!!!!!!!!!!!!!======================================="
		./$0 help "$@"
		;;		
	help)
		echo "Usage:"	
		echo "======================================"
		echo "- add run.sh script to Your project."
		echo "- include or '. /run-xxx.sh' in the script"
		echo "- add Your operations in Your run.sh"
		echo "- add Your operation before including if You want to override"
		echo "- add "
		echo "      COPY ./run-mydecent.sh /run-mydecent.sh && ln -sfn /run-mydecent.sh /r"
		echo "      RUN chmod a+x /run-mydecent.sh"
		echo " to Your dockerfile."
		echo "";
		case "$2" in
			apt)
				echo "apt OP [PACKAGE] [ARGS ...]"
				echo "Install/remove/search given package. "
				echo "OP=install - install package"
				echo "OP=search - search"
				echo "OP=remove - remove"
			;;
			*)
				echo "[i3c/run.sh ] No help on $2 available..."	
		esac		
esac