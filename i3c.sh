#!/bin/bash
#################################################################################  
#
#  					R&D platform in a single bash script ! 
#
#############################################################################################
#
#  !This software is free to use & modify as long as You will preserve this copyright notice! 
#
#  Copyright (c) 2014-2016 Mark Bisz (virtimus@gmail.com)
#
########################################################################################################
curl -s http://cbsg.sourceforge.net/cgi-bin/live | grep -Eo '^<li>.*</li>' | sed s,\</\\?li\>,,g | shuf -n 1
RED='\033[0;31m'
LRED='\033[1;31m'
NC='\033[0m' # No Color

# @description echo encapsulation
# @arg noarg
function _echo(){
	echo "$@"	
}

#@desc set -x  encapsulation
# @arg noarg
_setverbose() {
	set -x	
}

#
# echo filtered in verbose mode
#
_echov(){
if [ $i3cVerbose -ge 1 ]; then 	
	echo "$@"	
fi	
}

_echoe(){
(>&2 echo -e "${LRED}$@${NC}")
}
#get options
# A POSIX variable

#cho "input: '$@'"
# Initialize our own variables:
i3cOutputFile=""
i3cVerbose=0
i3cShowHelp=0
declare -A i3cOpt
i3cOpt[v]=0
i3cOpt[h]=0
i3cOpt[f]=""
i3cOptStr='';
declare -A i3cOptO
declare -A i3cOptStrs
#process options
doOpt=true;
#repeat until we have options with optional o required assiciated arguments
while $doOpt; do
	doOpt=false;
	OPTIND=1         # Reset in case getopts has been used previously in the shell.
	ind=0
	while getopts "h?vcof:" opt; do
		doOpt=false
	    case "$opt" in
	    c)	shift
	        ((ind++))
	        i3cOpt[c]=$1;
			shift
	        ((ind++))
	        doOpt=true;	    
	    	#. $1;
	    	;;	
	    h)  i3cShowHelp=1
	    	i3cOpt[h]=1 
	    	doOpt=false;
	        ;;
	    v)  i3cVerbose=1
	    	i3cOpt[v]=1
	        shift
	        ((ind++))
	        case $1 in
	          *[!0-2]* | "") ;;
	          *) 
	          	 i3cVerbose=$1;
	          	 i3cOpt[v]=$1; 
	          	 shift 
			     ((ind++))
			     doOpt=true;
			     ;;
	        esac          
	        ;;
	    f)  i3cOutputFile=$OPTARG
	    	i3cOpt[f]=1
	    	doOpt=false;
	        ;;
	    o)  shift
	        ((ind++))
	        i3cOptStr=$i3cOptStr' -o '$1;
	        doOpt=true;
	        echo 'argsgromo:'"$@"
	        IFS=':' read -ra ADDR <<< "$1"
	        oname=${ADDR[0]}
	        oval=${ADDR[1]}
			shift 
			((ind++))        
	    	i3cOptO[${oname}]=$oval;
	    	;;          
	    *)
	    	#_echo "Unknown option:"$opt  
	    	i3cOpt[$opt]=1 
	    	doOpt=false; 
	    esac
	done
	if [ $((OPTIND-1-$ind)) -ge 0 ]; then
		shift $((OPTIND-1-$ind))
	fi
	[ "${1:-}" = "--" ] && shift
	
	#xit 0
	
	#args=("$@")
	_echov "args:" "$@"
	if [ $i3cVerbose -ge 2 ]; then
	for var in "$@"
	do
	    echo "$var"
	done
	fi
done

#cho 'i3cOptO[vFrom]'${i3cOptO[vFrom]}

if [ $i3cVerbose -ge 2 ]; then
	_setverbose
fi

if [ "x${i3cOpt[c]}" != "x" ]; then
	. "${i3cOpt[c]}";
fi

case "$1" in
	gstorec)
		git config credential.helper store
		exit 0
		;;
	gcachec)
		
		timeoutSec="172800"; # 2 days
		if [ ! "x$2" = "x" ]; then 
			timeoutSec=$2
		fi	
		git config credential.helper cache --timeout=$timeoutSec
		exit 0
		;;
	gapi)
		cat /i | ./../i3c-dev-shdoc/shdoc > ./../i3c/i3c-cli-api.md
		exit 0
		;;		
	*)
	#noop
esac	

#domena glowna	
i3cHost=i3c.l

#host internal domain
i3cInHost=i3c.l

#host external domains
i3cExHost=i3c.h

#set from env if present
if [ "x$I3C_LOCAL_ENDPOINT" != "x" ]; then
    i3cExHost=$I3C_LOCAL_ENDPOINT
fi

#i3cHostIp=$(/sbin/ip route|awk '/default/ { print $3 }');	

#i3c platform root folder
i3cRoot="${I3C_ROOT}";
if [ "x${I3C_ROOT}" == "x" ]; then 
	#_echoe "FATAL ERROR: I3C_ROOT is not set. i3c.Cloud needs this to point to i3c working files ()."	
	#currently just /i3c as default & working
	i3cRoot='/i3c'
fi

#i3c platform data dir (containers have access here)
i3cDataDir=$i3cRoot'/data'

#i3c platform home dir
i3cHome="${I3C_HOME}";
if [ "x${I3C_HOME}" == "x" ]; then 
	#_echoe "FATAL ERROR: I3C_HOME is not set. i3c.Cloud needs this to point to i3c project files (https://github.com/i3c-cloud/i3c)."	
	#currently just [root]/i3c as default & working
	i3cHome=$i3cRoot'/i3c'; #'/i3c'
fi	


#log dir (normally containers should log here into subfolders)
i3cLogDir=$i3cRoot'/log'

#platform version
i3cVersion=v0

#folder name for imagedef collections
i3cDfFolder=dockerfiles

#default home uset for priority in path search
i3cDfHome=$i3cHome
#i3cDfDir=$i3cHome$i3cDfFolder

#user imagedef home (second priority in search)
if [ "x$I3C_UDF_HOME" = "x" ]; then
   I3C_UDF_HOME=$i3cDataDir'/i3c.user'
fi
i3cUdfHome=$I3C_UDF_HOME

declare -A i3cDFHomes
declare -A i3cDFFroms

#@description autoconfigure i3c user home dir
#  (currently only if imagedef folder exists
#
#@arg $1 - operation (create/readUHome/read/store)
#@arg $2 - folder
#@arg $3 - [optional] subfolder
_autoconf(){
case "$1" in
	create)
		if [ -e $2 ]; then
			if [ ! -e $2/.i3c ]; then 
				echo "i3cVersionAD=$i3cVersion" > $2/.i3c
				echo "i3cRootAD=$i3cRoot" >> $2/.i3c
				#cho "i3cUdfHome=$2" > $2/.i3c
				mkdir $2/$i3cDfFolder
				if [ "x$3" != "x" ]; then
					mkdir $2/$i3cDfFolder/$3 
				fi	
				return 0;
			else
				return 99;
			fi
		else
			return 98;		
		fi
		;;
	readUHome)
		currDir=$2;
		if [ -e $currDir'/.i3c' ]; then
			#. $currDir/.i3c
			i3cUdfHome=$currDir
		fi
		;;
	read)
		currDir=$2;
		if [ -e $currDir'/.i3c' ]; then
			. $currDir/.i3c
			#i3cUdfHome=$currDir
		fi
		;;
	readOptStrs)
		#cho '${i3cOptStrs[$2]}'${i3cOptStrs[$2]}
		if [ "x${i3cOptStrs[$2]}" != "x" ]; then
			optStr="${i3cOptStrs[$2]}";
			IFS=' ' read -ra ADDR <<< "$optStr"
			for K in "${!ADDR[@]}"; do
				os=${ADDR[$K]};
				if [ "x$os" != "x" ] && [ "$os" != "-o" ];then
					IFS=':' read -ra ADDR <<< "$os"
	        		oname=${ADDR[0]}
	        		oval=${ADDR[1]}
	        		if [ "x${i3cOptO[$oname]}" == "x" ]; then
	        			i3cOptO[$oname]=$oval;
	        		fi	 
				fi	
			done	
		fi
		#cho '$i3cOptO[vFrom]'${i3cOptO[vFrom]}
		;;		
	#TODO: real update	
	store)
		echo "#stored by i3c.sh version:"$i3cVersion > $i3cHome/.i3c
		for K in "${!i3cDFHomes[@]}"; do
			#echo $K; 
			#echo 	${i3cDFHomes[$K]}
			echo "i3cDFHomes["$K"]="${i3cDFHomes[$K]} >> $i3cHome/.i3c
		done	
		for K in "${!i3cDFFroms[@]}"; do
			#echo $K; 
			#echo 	${i3cDFHomes[$K]}
			echo "i3cDFFroms["$K"]="${i3cDFFroms[$K]} >> $i3cHome/.i3c
		done
		for K in "${!i3cOptStrs[@]}"; do
			#echo $K; 
			#echo 	${i3cDFHomes[$K]}
			echo "i3cOptStrs["$K"]='${i3cOptStrs[$K]}'" >> $i3cHome/.i3c
		done					
		;;						
	*)
		echo "Unknown autoconf operation:"$1;	
esac
}


currDir=$(pwd)
_autoconf readUHome $currDir 
_autoconf read $i3cHome 


#user folder to for saving/loading images (can grow big)	
#i3cUdfDir=$i3cDataDir'/i3cd/i3c-crypto/dockerfiles'
declare -r i3cUdiFolder=.dockerimages

#this folder shared between runnig containers 
#i3cUdiHome=$i3cDataDir'/i3cd'
declare -r i3cSharedFolder=.shared
	
#final (calculated) home dir for imagedef !tobe moved to i3cConfig	
i3cDfcHome=''

#docker binary name
declare -r dockerBin='docker'

#asoc array for user configs (run-config.sh)
declare -A i3cConfig;

#processing root config scripts
_procConfig(){

	if [ -e $i3cHome/i3c-config.sh ]; then
		. $i3cHome/i3c-config.sh	
	fi
	if [ -e $i3cHome.local/i3c-config.sh ]; then
		. $i3cHome.local/i3c-config.sh	
	fi
	if [ -e $i3cUdfHome/i3c-config.sh ]; then
		. $i3cUdfHome/i3c-config.sh		
	fi	
	if [ -e $PWD/i3c-config.sh ]; then
		. $PWD/i3c-config.sh	
	fi	
}

_procConfig;

#homedir for saved/loaded images
i3cUdiHome=$i3cRoot
if [ ! -e $i3cUdiHome/$i3cUdiFolder ]; then
	mkdir $i3cUdiHome/$i3cUdiFolder
fi

#homedir for .shared folder
i3cSharedHome=$i3cRoot
if [ ! -e $i3cSharedHome/$i3cSharedFolder ]; then
	mkdir $i3cSharedHome/$i3cSharedFolder
fi

	

#@desc load an image stored in imagedef dir into local docker repo 
#@arg $1 - image to load (appName)
load(){
	    doRm=''
		if [ ! -e $i3cUdiHome/$i3cUdiFolder/$1.i3ci ]; then 
			if [ -e $i3cUdiHome/$i3cUdiFolder/$1.i3czi ]; then
				unzip $i3cUdiHome/$i3cUdiFolder/$1.i3czi -d $i3cUdiHome/$i3cUdiFolder
				doRm=$i3cUdiHome/$i3cUdiFolder/$1.i3ci
			else
				echo "Saved image $1 not found."
			fi	
		fi	
	
		$dockerBin load -i $i3cUdiHome/$i3cUdiFolder/$1.i3ci
		$dockerBin tag 	i3c-tmp-save i3c/$1
		$dockerBin tag 	i3c-tmp-save i3c/$1:v0
		if [ "x$doRm" != "x" ]; then 
			rm $doRm
		fi			
}

#@desc save an image from local repo into imagedef dir (.i3ci)
#@arg $1 - appdef to save
save(){
		$dockerBin commit $1 i3c-tmp-save		
		$dockerBin save -o $i3cUdiHome/$i3cUdiFolder/$1.i3ci i3c-tmp-save 
}

#@desc save an image from local repo into imagedef dir as zipped (.i3czi)
#@arg $1 - appdef to save
savez(){
	save "$@"
	cd $i3cUdiHome/$i3cUdiFolder
	zip $1.i3czi $1.i3ci
	if [ $? -eq 1 ];then
		rm $i3cUdiHome/$i3cUdiFolder/$1.i3ci 
	fi 	
}



_procHomes(){
#i3cScriptDir='';
#i3cDfcHome='';	
line=$1;
sFile=$2;
			if [ "x${i3cDFHomes[$line]}" != "x" ]; then
				if [ -e ${i3cDFHomes[$line]}/$i3cDfFolder/$line/$sFile ]; then
					i3cDfcHome=${i3cDFHomes[$line]}
					i3cScriptDir=${i3cDFHomes[$line]}/$i3cDfFolder/$line
				fi
			fi
}

_procFroms(){
sFile=$1;
#scho '$cName:'$cName;
		if [ "x${i3cDFFroms[$cName]}" != "x" ]; then 
			line="${i3cDFFroms[$cName]}";
			#//ine="${line/\/i3c\//}"
			if [ "x${i3cDFHomes[$line]}" != "x" ]; then
				_procHomes $line $sFile;
			else
				echo "[procVars] ERROR: Home dir for inherited ${i3cDFFroms[$cName]} not found."
			fi	 					
		fi
	
}

#@desc processing different i3c platform config files 
# (normally process 'i3c-[command].sh' files according to current priorities
#@arg $@ -some args for taget script
_procVars(){
local sCommand=$1;
local cName=$2;	
local doFirsFound=0;
local doLastFound=0;
i3cScriptDir=''	
if [ "$sCommand" == 'run' ] || [ "$sCommand" == 'build' ]; then
	doLastFound=1
fi	
		_procFroms i3c-$sCommand.sh;

		if [ "x$i3cScriptDir" != "x" ]; then
					if [ $doLastFound -eq 0 ]; then
						. $i3cScriptDir/i3c-$sCommand.sh $@;
					fi
					if [ $doFirsFound -eq 1 ]; then
						return 0
					fi
		fi
		
		_procHomes $cName i3c-$sCommand.sh;

		if [ "x$i3cScriptDir" != "x" ]; then
					if [ $doLastFound -eq 0 ]; then
						. $i3cScriptDir/i3c-$sCommand.sh $@;
					fi
					if [ $doFirsFound -eq 1 ]; then
						return 0
					fi
		fi		
	
		if [ -e $i3cDfHome/$i3cDfFolder/$cName/i3c-$sCommand.sh ]; then
			i3cDfcHome=$i3cDfHome
			i3cScriptDir=$i3cDfHome/$i3cDfFolder/$cName
			if [ $doLastFound -eq 0 ]; then
				. $i3cScriptDir/i3c-$sCommand.sh $@;
			fi
			if [ $doFirsFound -eq 1 ]; then
				return 0
			fi	
		fi
		if [ -e $i3cDfHome.local/$i3cDfFolder/$cName/i3c-$sCommand.sh ]; then
			i3cDfcHome=$i3cDfHome'.local'
			i3cScriptDir=$i3cDfHome.local/$i3cDfFolder/$cName
			if [ $doLastFound -eq 0 ]; then
				. $i3cScriptDir/i3c-$sCommand.sh $@;
			fi
			if [ $doFirsFound -eq 1 ]; then
				return 0
			fi			
		fi		
		if [ -e $i3cUdfHome/$i3cDfFolder/$cName/i3c-$sCommand.sh ]; then
			i3cDfcHome=$i3cUdfHome
			i3cScriptDir=$i3cUdfHome/$i3cDfFolder/$cName
			if [ $doLastFound -eq 0 ]; then
				. $i3cScriptDir/i3c-$sCommand.sh $@;
			fi
			if [ $doFirsFound -eq 1 ]; then
				return 0
			fi			
		fi
		if [ -e $i3cUdfHome.local/$i3cDfFolder/$cName/i3c-$sCommand.sh ]; then
			i3cDfcHome=$i3cUdfHome'.local'
			i3cScriptDir=$i3cUdfHome.local/$i3cDfFolder/$cName
			if [ $doLastFound -eq 0 ]; then
				. $i3cScriptDir/i3c-$sCommand.sh $@;
			fi
			if [ $doFirsFound -eq 1 ]; then
				return 0
			fi			
		fi
		if [ $doLastFound -eq 1 ]; then
			if [ "$i3cScriptDir" != '' ]; then
				. $i3cScriptDir/i3c-$sCommand.sh $@;
				return 0;
			fi	
		fi
						
return 1		
}

#@desc given an git repo and folder take docker imagedef for later build and pull to local repo
# !todo - option -b for automatic build and use from /i level (requires extractind _buildint from build)

#@arg $1 repo url (ie https://github.com/swagger-api)
#@arg $2 folder name inside the repo

#@example 1
#   used ie in i3c-build.sh scripts:
#   i3c-openapi/swagger-editor
_imageClonePullForBuild(){
appName=$2
dfFolder=$(basename $i3cDfcHome)
if [ ! -e $i3cDataDir/$dfFolder/$cName/$appName ]; then
	cd $i3cDataDir
	mkdir $dfFolder
	cd $dfFolder
	mkdir $cName
	cd $cName
	git clone --depth 1 $1/$appName.git
else
	cd $i3cDataDir/$dfFolder/$cName/$appName
	git pull
fi
i3cDfHome=$i3cDataDir/$dfFolder
i3cDfFolder=$cName
}

#not tested
_exist(){
$dret="$(docker ps -a | grep bracs_output)";
return "$?";	
}


_cloneOrPull(){

appName=$cName;
folder=$i3cDataDir/$appName/$2
    
    if [ ! -e $i3cDataDir/$appName/$2 ]; then
    	if [ ! -e $i3cDataDir/$appName ]; then
    		mkdir $i3cDataDir/$appName
    	fi
    	cd $i3cDataDir/$appName
    	git clone $1
	else
		cd 	$folderWithDockerF
		git pull	
	fi
	
}

#@desc clone given 3d party repo

#@arg $1 repo path
#@arg $2 dockerfile folder inside this repo (the path will be available in container under /i3c/data)
#@arg $3 image/container name to build
#@arg $4 optional arg for image name if different than appName 


#@alias cldb
cloneUDfAndBuild(){
	doCommand=true
	dCommand=$dockerBin' build'
	sCommand=cldb
	imP=$3
	IFS='/' read -r -a arrIN <<< "$3"
	appName=${arrIN[0]};
	cName=$appName
	iName=$3

folderWithDockerF=$i3cDataDir/$appName/$2
    
    if [ ! -e $i3cDataDir/$appName/$2 ]; then
    	if [ ! -e $i3cDataDir/$appName ]; then
    		mkdir $i3cDataDir/$appName
    	fi
    	cd $i3cDataDir/$appName
    	git clone $1
	else
		cd 	$folderWithDockerF
		git pull	
	fi

	
	i3cDfHome=$i3cDataDir	
	i3cDfFolder=$appName
	iPath=$2
	
	_build $iName	
}

#@desc clone a workspace from git, build and run given git repo, imagedef/app name and also name of container to run
#@alias clur

#@arg $1 repo path (ie https://github.com/virtimus 
#@arg $2 repo name (ie i3c-openapi)
#@arg $3 imagedef/containder name (ie swagger-editor)

#@example 1
#    /i clur https://github.com/virtimus i3c-openapi swagger-editor
cloneUdfAndRun(){
	cd $i3cRoot
	if [ -e $i3cRoot/$2 ]; then
		echo "Folder "$i3cRoot/$2." exists ... runing pull ..."
		cd $i3cRoot/$2
		git pull
	else
		git clone $1/$2	 	 
	fi	 	
	i3cUdfHome=$i3cRoot/$2
	#create local i3c autoconf
	_autoconf create $i3cUdfHome
	rebuild $3
	rerun $3
}

cloneDfAndBuild(){
	cloneUDfAndBuild "$@"
	return "$?";
}


#@desc up with composer (if docker-compose.yml file present)
#or try to rebuild & rerun
#@arg $1 appDef
up(){
ret=0;	
		doCommand=true
		
		
		cName=$1
		
		dCommand='docker-compose -p '$cName' up'
	
	#todo! integrate with build version	
	dfHome=''	
	if [ -e $i3cDfHome/$i3cDfFolder/$cName/docker-compose.yml ]; then
		dfHome=$i3cDfHome 
	fi		
	if [ -e $i3cDfHome.local/$i3cDfFolder/$cName/docker-compose.yml ]; then
		dfHome=$i3cDfHome'.local' 
	fi		
	if [ -e $i3cUdfHome/$i3cDfFolder/$cName/docker-compose.yml ]; then
		dfHome=$i3cUdfHome 
	fi
	if [ -e $i3cUdfHome.local/$i3cDfFolder/$cName/docker-compose.yml ]; then
		dfHome=$i3cUdfHome'.local' 
	fi	
	if [ "x$dfHome" != "x" ]; then
		uData=$i3cDataDir/$cName;
		uLog=$i3cLogDir/$cName;
		iName=$1;
		
		_procConfig;				
		sCommand='config'
		_procVars $sCommand $cName;		
		sCommand=up
		_procVars $sCommand $cName;
		#cName readonly here ?
		cName=$1
		
		
		
		if [ "x$i3cImage" = "x" ]; then		
			i3cImage=i3c/$iName
		fi
		if [ "x$iPath" = "x" ]; then		
			iPath=$iName
		fi		
		if [ $doCommand == true ]; then
			cd $dfHome/$i3cDfFolder/$cName
			_echov "$dCommand $dParams"
			$dCommand $dParams
			ret=$?; 
			#-t $i3cImage:$i3cVersion -t $i3cImage:latest $i3cDfHome/$i3cDfFolder/$iPath/.
		fi
	else
		#try to rebuild/rerun?
		rebuild "$@";
		ret=$?;
			if [ $ret -eq 0 ]; then
	    		rerun "$@";		
			fi
	fi
	return $ret;		
}

#well, for a complete clear one currently has to use his own i3c-down script
down(){
	cName=$1;
	_procConfig;
	sCommand='config';
	_procVars $sCommand $cName;	
	sCommand=down
	_procVars $sCommand $cName;	
}

#@desc build with docker
#@arg $1 - appDef
build(){
#	if [ -e $i3cUdfHome/$i3cDfFolder/$1/i3c-build.sh ]; then
#		i3cDfHome=$i3cUdfHome 
#	fi
#	if [ -e $i3cDfHome/$i3cDfFolder/$1/i3c-build.sh ]; then
#		. $i3cDfHome/$i3cDfFolder/$1/i3c-build.sh
#	else
		doCommand=true
		dCommand=$dockerBin' build'
		
		cName=$1
		iName=$1
	
	#for use in .i3c file	
	dfHome=''	
	if [ -e $i3cDfHome/$i3cDfFolder/$cName/dockerfile ] || [ -e $i3cDfHome/$i3cDfFolder/$cName/Dockerfile ] || [ -e $i3cDfHome/$i3cDfFolder/$cName/i3c-build.sh ]; then
		dfHome=$i3cDfHome 
	fi				
	if [ -e $i3cDfHome.local/$i3cDfFolder/$cName/dockerfile ] || [ -e $i3cDfHome.local/$i3cDfFolder/$cName/Dockerfile ] || [ -e $i3cDfHome.local/$i3cDfFolder/$cName/i3c-build.sh ]; then
		i3cDfHome=$i3cDfHome'.local' 
		dfHome=$i3cDfHome
	fi		
	if [ -e $i3cUdfHome/$i3cDfFolder/$cName/dockerfile ] || [ -e $i3cUdfHome/$i3cDfFolder/$cName/Dockerfile ] || [ -e $i3cUdfHome/$i3cDfFolder/$cName/i3c-build.sh ]; then
		i3cDfHome=$i3cUdfHome
		dfHome=$i3cDfHome 
	fi
	if [ -e $i3cUdfHome.local/$i3cDfFolder/$cName/dockerfile ] || [ -e $i3cUdfHome.local/$i3cDfFolder/$cName/Dockerfile ] || [ -e $i3cUdfHome.local/$i3cDfFolder/$cName/i3c-build.sh ]; then
		i3cDfHome=$i3cUdfHome'.local'
		dfHome=$i3cDfHome 
	fi
	
	if [ "x$dfHome" != "x" ]; then		
		i3cDFHomes[$cName]=$dfHome
		i3cOptStrs[$cName]=$i3cOptStr
		_autoconf store
	fi 
	
	uData=$i3cDataDir/$cName;
	uLog=$i3cLogDir/$cName;		
	
	_procConfig;
	sCommand='config';
	_procVars $sCommand $cName;	
	sCommand=build
	_procVars $sCommand $cName;
	#cho "==========================="
	if [ "x$dfHome" == "x" ]; then
		_procHomes $cName i3c-build.sh;
		if [ "x$i3cDfcHome" != "x" ]; then
			i3cDfHome=$i3cDfcHome;
			dfHome=$i3cDfHome 
		fi	
	fi
	if [ "x$dfHome" == "x" ]; then
		_procHomes $cName dockerfile;
		if [ "x$i3cDfcHome" != "x" ]; then
			i3cDfHome=$i3cDfcHome;
			dfHome=$i3cDfHome 
		fi	
	fi
	if [ "x$dfHome" == "x" ]; then
		_procHomes $cName Dockerfile;
		if [ "x$i3cDfcHome" != "x" ]; then
			i3cDfHome=$i3cDfcHome;
			dfHome=$i3cDfHome 
		fi	
	fi	
		
	_build $1
	ret=$?;
	if [ $ret -ne 0 ]; then
		return $ret;	 
	fi	
	if [ -n "$(type -t i3cAfter)" ] && [ "$(type -t i3cAfter)" = function ]; then
		i3cAfter $@;
		unset -f i3cAfter;
		ret=$?;
	fi	
	
	return $ret;
#	fi		
}


#@desc internal build part
#@arg $1 - appDef
_build(){
	
		iName=$1
		#cName=$1
				
		if [ "x$i3cImage" = "x" ]; then		
			i3cImage=i3c/$iName
		fi
		if [ "x$iPath" = "x" ]; then		
			iPath=$iName
		fi		
		if [ $doCommand == true ]; then
			#check dependencies	
			fromClause=""
			doCommand=false
			if [ -e $i3cDfHome/$i3cDfFolder/$iPath/dockerfile ]; then 
				fromClause="$(cat  $i3cDfHome/$i3cDfFolder/$iPath/dockerfile | sed  -e '/^FROM i3c/!d')"
				doCommand=true;
			elif [ -e $i3cDfHome/$i3cDfFolder/$iPath/Dockerfile ]; then
				fromClause="$(cat  $i3cDfHome/$i3cDfFolder/$iPath/Dockerfile | sed  -e '/^FROM i3c/!d')"
				doCommand=true;
			fi
			if [ $doCommand == true ]; then
				if [ "x${i3cOptO[skipFroms]}" == "x" ] && [ "x$fromClause" != "x" ]; then 
					while read -r line; do
						if [ -n "$line" ]; then
							line="${line/FROM i3c\//}"	
							i3cDFFroms[$cName]=$line;
							_autoconf store;
	    					echo "==================================================="
	    					echo " REBUILDING Base image: $line ..."
	    					echo "==================================================="
	    					/i $i3cOptStr rebuild $line
							echo " ENDED REBUILDING Base image: $line ..."
	    					echo "==================================================="	    					
	    				fi
					done <<< "$fromClause"
				fi
				if [ ${i3cOpt[v]} -le 1 ]; then
					echo "$dCommand $dParams -t $i3cImage:$i3cVersion -t $i3cImage:latest $i3cDfHome/$i3cDfFolder/$iPath/."
				fi	
				$dCommand $dParams -t $i3cImage:$i3cVersion -t $i3cImage:latest $i3cDfHome/$i3cDfFolder/$iPath/.
			else
				_echoe "appDef "$iPath" not found.";
				return 1;					
			fi
		fi
	return 0;
}

#@desc scheck if running
#@arg $1 - appDef
_checkRunning(){
docker inspect -f {{.State.Running}} $1 | grep 'true' > /dev/null
if [ $? -eq 0 ]; then
  echo "checkRunning: Process $1 is running."
  return 0;
else
  echo "checkRunning: Process $1 is not running."
  return 1;
fi
}

#@desc check if runing and run
#@arg $1 - appDef
crun(){
	_checkRunning $1;
	if [ $? -eq 1 ]; then
		rerun $@;
	fi			
}

_sanitCName(){
 	echo "$1" | sed -r 's/[\/]+/_/g'	
}

#@desc run given container by name
#@arg $1 - appDef 
run(){
#echo 'run:'$@;	


# check home folder & cd if needed
if [ ${i3cDFHomes[$1]+_} ]; then 
	echo 'changing current dir to:'${i3cDFHomes[$1]}'...'
	cd ${i3cDFHomes[$1]}
	currDir=$(pwd)
	_autoconf readUHome $currDir	
fi	
	
	
		doCommand=true
		cName=$1
		iName=$1
		dCommand=$dockerBin' run'
		# for config convenience
		uData=$i3cDataDir/$cName;
		uLog=$i3cLogDir/$cName;
		addVHost='';
		
		_autoconf readOptStrs $cName;
		
		_procConfig;
		sCommand='config';
		_procVars $sCommand $cName;		
		
		#configure run
		sCommand=run-config
		_procVars $sCommand $cName;
		
		sCommand=run
		_procVars $sCommand $cName;
		
		#check if need to proces base files
		if [ "$1" == "$iName" ]; then
			#cName here is readonly
			cName=$1;
			echo ""
		fi
		if [ "x$i3cParams" = "x" ]; then
lOpts='';
if [ "x${i3cOptO[timeSync]}" != "x" ]; then
	lOpts="$lOpts -v /etc/localtime:/etc/localtime:ro";
fi			
			
i3cParams=" $lOpts \
	-v $i3cDataDir/$cName:/i3c/data \
	-v $i3cHome:/i3c/i3c \
	-v $i3cLogDir/$cName:/i3c/log \
	-v $i3cSharedHome/$i3cSharedFolder:/i3c/.shared \
	-e VIRTUAL_HOST=$cName.$i3cInHost,$cName.$i3cExHost$addVHost \
	-e I3C_ROOT=/i3c \
	-e I3C_LOCAL_ENDPOINT=$I3C_LOCAL_ENDPOINT \
	-e I3C_HOST=$i3cHost \
	-e I3C_HOME=/i3c/i3c \
	-e I3C_DATA_DIR=/i3c/data \
	-e PWD_ENV=$PWD_ENV \
	-e I3C_LOG_DIR=/i3c/log"
	
oParams="";
if [ "x${i3cOptO[restart]}" != "x" ]; then
	oParams=$oParams' --restart '${i3cOptO[restart]}
fi		
	
	
	# make sure shared subfolder is created
	if [ ! -e $i3cSharedHome/$i3cSharedFolder/$cName ]; then
		mkdir $i3cSharedHome/$i3cSharedFolder/$cName
	fi	   
					
		fi
		#if choosen - add /i config
		i3iParams='';
		if [ "$addIParams" == true ]; then
			i3iParams="	-v $i3cUdiHome/$i3cUdiFolder:$i3cUdiHome/$i3cUdiFolder \
						-v /var/run/docker.sock:/var/run/docker.sock"
		fi	
		
		if [ "x$i3cImage" = "x" ]; then		
			i3cImage=i3c/$iName
		fi	
		if [ "x$rCommand" = "x" ]; then
			rCommand="${@:2}";
		fi
		if [ "$doCommand" == true ]; then
			if [ ${i3cOpt[v]} -le 1 ]; then
				echo $dCommand --name $(_sanitCName $1) \
					 $oParams \
					 $i3cParams \
					 $i3iParams \
					 $dParams \
					 $i3cImage:$i3cVersion \
					 $rCommand \
					 $rParams
			fi	
					#cho "dParams:$dParams"	
					 $dCommand --name $(_sanitCName $1) \
					 $oParams \
					 $i3cParams \
					 $i3iParams \
					 $dParams \
					 $i3cImage:$i3cVersion \
					 $rCommand \
					 $rParams 			
		fi
		if [ -n "$(type -t i3cAfter)" ] && [ "$(type -t i3cAfter)" = function ]; then
			i3cAfter $@;
			unset -f i3cAfter;
		fi
		
	return $?;
#docker exec  $1 sh -c "echo \$(/sbin/ip route|awk '/default/ { print \$3 }')' $i3cHost' >> /etc/hosts"
}

#echo "echo \$(/sbin/ip route|awk '/default/ { print \$3 }')' $i3cHost' >> /etc/hosts"

#@desc remove container by name
#@arg $1 - appDef
_rm(){
	sCommand='rm';
	doCommand=true;
	cName=$1
	_procVars $sCommand $cName;
	if [ "$doCommand" == true ]; then
		ret=1;		
		$dockerBin rm $(_sanitCName $1);
		ret=$?;
		return $ret;
	fi
	return 0;
}

psFormat="table {{.Names}}\t{{.Status}}\t{{.Image}}\t{{.Size}}\t{{.Ports}}"

#@desc list runing containers
#@na
psa(){
	ret=1;	
	$dockerBin ps -a --format "$psFormat"
	ret=$?;
	return $ret;	
}

#@desc list all containers
#@na
_ps(){
	ret=1;	
	$dockerBin ps --format "$psFormat"
	ret=$?;
	return $ret;	
}

#@desc remove all dangling images
#@na
rmidangling(){
	ret=1;	
	$dockerBin rmi $(docker images -a -q --filter "dangling=true")
	ret=$?;
	return $ret;   
}

#@desc start stopped container
#@arg $1 - appDef
start(){
	ret=1;	
	$dockerBin start $(_sanitCName $1);
	ret=$?;
	return $ret;
}

#@desc stop runing container
#@arg $1 - appDef
stop(){
	ret=1;	
	$dockerBin stop $(_sanitCName $1);
	ret=$?;
	return $ret;
}

#@desc pid
#@arg $1 - appDef
pid(){
	ret=1;	
	$dockerBin inspect --format '{{ .State.Pid }}' "$@"
	ret=$?;	
	return $ret;	
}

#@desc ip
#@arg $1 - appDef
ip(){
	ret=1;	
	$dockerBin inspect --format '{{ .NetworkSettings.IPAddress }}' "$@"
	ret=$?;	
	return $ret;		
}

#@desc logs
#@arg $1 - appDef
logs(){
	ret=1;	
	$dockerBin logs -f "$(_sanitCName $1)"
	ret=$?;	
	return $ret;	
}

#@desc use midnight commander on container
_mc(){
	ret=1;	
	cNameSanit="$(_sanitCName $1)"
	cFsPath=/proc/$(docker inspect --format {{.State.Pid}} $cNameSanit)/root/
	if [ "x${DOCKER_HOST}" == "x" ]; then
		#local one	
		mc $PWD $cFsPath
	else
		#remote
		dHost=$(echo $DOCKER_HOST | sed 's/tcp:\/\/\(.*\)[:]\(.*\)/sh:\/\/docker@\1/')
		echo "dHost:$dHost"
		mc $PWD $dHost$cFsPath
	fi		
	
	#$dockerBin logs -f "$(_sanitCName $1)"
	ret=$?;	
	return $ret;
}

#@desc stats
#@arg $1 - appDef
stats(){
	ret=1;	
	$dockerBin stats "$(_sanitCName $1)"
	ret=$?;	
	return $ret;	
}

#@desc run command on container using sh -it
#@arg $1 - appDef
#@arg ${@:2} - command(s)
exsh(){
	ret=1;	
	$dockerBin exec -it $(_sanitCName $1) sh -c "${@:2}";
	ret=$?;	
	return $ret;	
}

#@desc run command on container using sh non-interactive
#@arg $1 - appDef
#@arg ${@:2} - command(s)
exshd(){
	ret=1;	
	$dockerBin exec $(_sanitCName $1) sh -c "${@:2}";
	ret=$?;	
	return $ret;	
}

#@desc run command on container -it
#@arg $1 - appDef
#@arg ${@:2} - command(s)
exec(){
	ret=1;	
	$dockerBin exec -it $(_sanitCName $1) "${@:2}";
	ret=$?;	
	return $ret;
}

#@desc run command on container non-interactive
#@arg $1 - appDef
#@arg ${@:2} - command(s)
execd(){
	ret=1;	
	$dockerBin exec $(_sanitCName $1) "${@:2}";
	ret=$?;	
	return $ret;	
}

#@desc tag a container
#@arg $1 - appDef
#@arg ${@:2} - rest of args
tag(){
	ret=1;	
	$dockerBin tag $(_sanitCName $1) "${@:2}";
	ret=$?;	
	return $ret;	
}

#@desc list images !todo
#@na	
images(){

#result=$( sudo docker images -q nginx )

#if [[ -n "$result" ]]; then
#  echo "Container exists"
#else
#  echo "No such container"
#fi
#docker contaianers ls -f name =$1

echo ""
	
}

#@desc stop, remove and build container by name
#@arg $1 - appDef
rebuild(){
ret=0;	
	_echov "--------------------"
	_echov "rebuild starting ..."
	    #>/dev/null
		e1=$(stop $1 2>&1);
		r1=$?;
    	e2=$(_rm $1 2>&1);
    	r2=$?;
    	if [ $r1 -ge 0 ]; then
    		r1=$r1"("$e1")"
    	fi
		if [ $r2 -ge 0 ]; then
    		r2=$r2"("$e2")"
    	fi    		
    	_echov "stoping returned: $r1, remove returned: $r2 ..."
    	build $1; 
    	ret=$?;
    _echov "rebuild returned:$ret"	
    	return $ret;
}

#@desc stop, remove and run container by name
#@arg $1 - appDef
rerun(){
		e1=$(stop $1 2>&1);
		r1=$?;
    	e2=$(_rm $1 2>&1);
    	r2=$?;
		if [ $r1 -ge 0 ]; then
    		r1=$r1"("$e1")"
    	fi
		if [ $r2 -ge 0 ]; then
    		r2=$r2"("$e2")"
    	fi    	
    	_echov "stop=$r1, rm=$r2 ..."
    	run "$@";
    	return $?;
}

#@desc get new certificate for given subdomain(ie container name)
# currently using certbot/letsgetencrypt
#@arg $1 - appDef
cert(){
	
if [ ! -e $i3cDataDir/.certs ]; then
	mkdir $i3cDataDir/.certs
fi
if [ ! -e $i3cDataDir/.certslib ]; then
	mkdir $i3cDataDir/.certslib
fi		
	
#configure run
cnName=$1;
fullDomain=$cnName.$i3cExHost
stop i3cp

$dockerBin run -it --rm --name certbot -p 80:80 -p 443:443 -v $i3cDataDir/.certs:/etc/letsencrypt -v  $i3cDataDir/.certslib:/var/lib/letsencrypt certbot/certbot certonly --register-unsafely-without-email --standalone -d $fullDomain

cp $i3cDataDir/.certs/live/$fullDomain/cert.pem $i3cDataDir/i3cp/certs/$fullDomain.crt
cp $i3cDataDir/.certs/live/$fullDomain/privkey.pem $i3cDataDir/i3cp/certs/$fullDomain.key

#restart i3cp

rerun i3cp

}

#@desc initialize new user workspace in current folder, no args needed
#@na
winit(){
p=$(pwd)
_autoconf create $p	
ret=$?;
if [ $ret -eq 0 ]; then 
	_echo "i3c.Cloud workspace initialized properly ..."
elif [ $ret -eq 99 ]; then
	_echo "i3c.Cloud workspace already initialized."	
else
	_echo "Init problem:"$ret;
fi		
}

#@ add appdef in current workspace
#@arg $1 - appDef
wadd(){	
	if [ "x$1" == "x" ]; then
		echo "Must provide name of appdef to create"	
	fi
	
	if [ ! -e $i3cUdfHome/$i3cDfFolder/$1 ]; then 
		mkdir $i3cUdfHome/$i3cDfFolder/$1
	fi
}

#@desc cp into or from container
#@arg $@ - same as docker cp
_cp(){
	ret=1;	
	$dockerBin cp "$@";
	ret=$?;	
	return $ret;	
	}
	
#@desc list images
#@arg $@ - same as docker images	
function images(){
	$dockerBin images "$@";
}	

_fromCase=1
case "$1" in
	images)
		images "${@:2}";
		;;
	up)
		up "${@:2}";
		;;
	down)
		down "${@:2}";
		;;
	build)
 		build "$2";
        ;;	
	run)
 		run "${@:2}";
        ;;	
	runb)
 		runb "$2";
        ;;	
	start)
 		start "$2";
        ;;
	stop)
 		stop "$2";
        ;;		
	rm)
 		_rm "$2";
        ;;
	ps)
 		_ps "$2";
        ;;		
	psa)
 		psa "$2";
        ;;	        
    rmi)
    	rmidangling "$2";
    	;;	    
    rb|rebuild)
    	rebuild "${@:2}";    
        ;;
    rr|rerun)
		rerun "${@:2}";    
	    ;;
	rbrr)
	    /i rb "${@:2}";
	    ret=$?;
		if [ $ret -eq 0 ]; then
	    	/i rr "${@:2}";
		fi	
	    ;;	
    crun)
    	crun "${@:2}";
    	;;  	
	pid)
		pid "$2";
		;;
	ip)
		ip "$2";
		;;
	exsh)
		exsh "${@:2}";
		;;
	exshd)
		exshd "${@:2}";
		;;		
	ex|exec)
		exec "${@:2}";
		;;
	exbb)
		exec $2 /bin/bash;
		;;		
	exe|execd)
		execd "${@:2}";
		;;			
	save)
		save "$2";
		;;
	savez)
		savez "$2";
		;;		
	load)
		load "$2";
		;;								
	logs)
		logs "$2";
		;;
	tag)
		tag "${@:2}";
		;;	
	clur|cloneUdfAndRun)
		cloneUdfAndRun "${@:2}";
		;;
	cldb|cloneDfAndBuild|cloneUDfAndBuild)
		cloneDfAndBuild "${@:2}";
		;;
	cert)
		cert "${@:2}";
		;;
	cp) _cp "${@:2}";
		;;	
	wi|winit)
		winit "${@:2}";
		;;
	wa|wadd)
		wadd "${@:2}";
		;;	
	stats)
		stats "${@:2}";
		;;	
	mc)	
		_mc "${@:2}";
		;;	
	*)
			echo "Basic usage: $0 up|build|run|runb|start|stop|rm|ps|psa|rmi|rebuild|rerun|pid|ip|exec|exe|save|load|logs|cloneUdfAndRun|help...";
			echo "cmdAliases:"
			echo "rb=rebuild"
			echo "rr=rerun"
			echo "rbrr=rebuild and rerun"
			echo "clur=cloneUdfAndRun"
			echo "Help with command: $0 help [commmand]";
			echo "====================="
			echo "Some usefull shortcuts:"
			echo "gstorec - git config credential.helper store"			
esac
 	

#tu skrypty




