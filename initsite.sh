#!/bin/bash
# https://github.com/cihantuncer/InitSite
# (c) 2024, Cihan Tuncer - cihan@cihantuncer.com
# This script is licensed under MIT license (see LICENSE.md for details)

# Default variables

scname=$(basename "$0")
scname="${scname%.*}"
scvers="1.0.9"


# --- Get Script Path -----------------------------------------------

SCRIPT_PATH="${BASH_SOURCE[0]:-$0}"

while [ -h "$SCRIPT_PATH" ]; do
    cd "$( dirname -- "$SCRIPT_PATH" )"
    SCRIPT_PATH="$( readlink -f -- "$SCRIPT_PATH" )"
done

cd "$( dirname -- "$SCRIPT_PATH" )"
SCRIPT_PATH="$( pwd )"
SCRIPT_FILE="$SCRIPT_PATH/$scname.sh"

# --- Check root privileges ----------------------------------------

if [[ $EUID -ne 0 ]]; then

	echo ""
	echo "$scname must be run as root, exited."
	echo ""
	exit 1
fi


# --- Setup ------------------------------------------------------

setupErr=0

function symlinkToBin {

	local srcFile=$1
	local fileName=$2

	if [ -f "$srcFile" ]; then

		ln -sf "$srcFile" "/usr/bin/$fileName"

		if [ $? -eq 0 ]; then
			echo "Symbolic link created in /usr/bin/$fileName"
			echo "Now you can run the script using just its name: '$fileName <command> <arguments>'"
		else
			echo "Error: $fileName could not be moved to '/usr/bin'."
			setupErr=1
		fi
		
	else
		echo "Error: Script not found: $srcFile"
		setupErr=1
	fi

}

function setup {
	
	source $SCRIPT_PATH/src/inc/style.inc.sh

	local destPath=""
	local scPath="$SCRIPT_PATH"
	local scFile=""
	local moved=0

	echo ""
	echo "============ $scname Setup ============"
	echo ""
	style "<yellow>Move $scname folder to another directory?"

	while true; do
    
    	read -p "Enter target dir or leave empty (Current $(dirname $SCRIPT_PATH)):" inpt
        
	    if [ -n "$inpt" ]; then
		    
			if [ -d "$inpt" ]; then
				destPath="$inpt"
				break;
			else
				style "<red>Error: Destination path does not exist."
				echo ""
			fi
		else
		    break;
		fi
	done

	echo ""

	if [ -n "$destPath" ]; then

		cp -r "$SCRIPT_PATH" "$destPath"

		if [ $? -eq 0 ]; then

			destPath="${destPath%/}"
			scPath="$destPath/$scname"
			moved=1

			echo "$scname moved to $destPath"

		else
			style "<red>Error: $scname could not be moved to $destPath"
			echo ""
			setupErr=1
		fi
	fi

	scFile="$scPath/$scname.sh"

	if [ -f "$scFile" ]; then
		chmod +x "$scFile"
		symlinkToBin "$scFile" "$scname"
	else
		echo "Error: $scname does not exist in $scPath."
		setupErr=1
	fi

	if [[ "$setupErr" == "1" ]]; then
		echo ""
		style "<yellow>$scname setup completed with errors."
	else
		echo ""
		style "<green>$scname installed successfully."
	fi

	echo ""
	echo "================================="
	echo ""

	if [[ "$moved" == "1" ]]; then
		rm -rf "$(dirname "$BASH_SOURCE")"
	fi

	exit
}

if [[ $1 == *"setup"* ]]; then
	setup
	exit
fi


# --- Imports ------------------------------------------------------

source $SCRIPT_PATH/settings.conf

for script in "$SCRIPT_PATH/src/inc"/*
do
  source $script
done

# --- Default Variables For Fallback -------------------------------

curl_enabled=1
scriptEWIS=""

if [ -z "$apache_sitesAvailableDir"     ]; then apache_sitesAvailableDir="/etc/apache2/sites-available";              fi
if [ -z "$apache_sitesEnabledDir"       ]; then apache_sitesEnabledDir="/etc/apache2/sites-enabled";                  fi
if [ -z "$vhost_serverRootDir"          ]; then vhost_serverRootDir="/var/www";                                       fi
if [ -z "$certificate_certsDir"         ]; then certificate_certsDir="/etc/apache2/certificates/certs";               fi
if [ -z "$certificate_keysDir"          ]; then certificate_keysDir="/etc/apache2/certificates/keys";                 fi
if [ -z "$certificate_default_certFile" ]; then certificate_default_certFile="/etc/ssl/certs/ssl-cert-snakeoil.pem";  fi
if [ -z "$certificate_default_keyFile"  ]; then certificate_default_keyFile="/etc/ssl/private/ssl-cert-snakeoil.key"; fi
if [ -z "$hosts_file"                   ]; then hosts_file="/etc/hosts";                                              fi
if [ -z "$dns_port"                     ]; then dns_port=22;                                                          fi
if [ -z "$webserver_ip"                 ]; then webserver_ip=$(hostname -I);                                          fi
if [ -z "$folder_perm"                  ]; then folder_perm="0755";                                                   fi
if [ -z "$file_perm"                    ]; then file_perm="0644";                                                     fi
if [ -z "$php_dir"                      ]; then php_dir="/etc/php";                                                   fi


# Checks mandatory/optional dependencies
function checkDependencies {

	# apache
	if ! command -v apachectl > /dev/null 2>&1; then

		msgErr "<red>Apache</red><yellow> is missing. This script is designed for development environments with Apache."
		echo ""
		exitScript 1
	fi

	# php
	if ! command -v php > /dev/null 2>&1; then

		msgErr "<red>PHP</red><yellow> is missing. This script is designed for development environments with PHP."
		echo ""
		exitScript 1
	fi

	#php-fpm
	if dpkg -l | grep -q php-fpm || rpm -q php-fpm >/dev/null 2>&1; then

		php_fpm=1

    else

		php_fpm=0
        msgWarn "<red>PHP-FPM</red><yellow> processor is not installed on the server. Default PHP $php_ver_default version will be used."
    fi


	# sshpass
	if ! command -v sshpass > /dev/null 2>&1; then

		if [[ $dns_pass ]]; then

			dns_server=0
			msgWarn "<red>sshpass</red><yellow> is missing. SSH connection with password to DNS server is _disabled_."
			msgWarn "Install it from your distro's repository to enable."
			msgWarn "If you can connect to the DNS server with SSH key-based authentication,"
			msgWarn "leave 'dns_pass' variable empty in settings.conf to switch to that method."
			echo ""
		fi

	fi

	# mkcert
	if ! command -v mkcert > /dev/null 2>&1; then
		
		certificate_generate=0
		msgWarn "<red>mkcert</red><yellow> is missing. Generation of the certificate files will be _disabled_."
		msgWarn "Install mkcert to enable certificate generation."
		msgWarn "https://github.com/FiloSottile/mkcert"
		echo ""
	fi

	# curl
	if ! command -v curl > /dev/null 2>&1; then
		
		curl_enabled=0
		msgWarn "<red>curl</red><yellow> is missing. Http requests for testing will be _disabled_."
		msgWarn "Install it from your distro's repository to enable."
		echo ""
	fi

	syssvc=1
	# service
	if ! command -v service > /dev/null 2>&1; then
		syssvc=0
	fi

	sysctl=1
	# systemctl
	if ! command -v systemctl > /dev/null 2>&1; then
		sysctl=0
	fi
}

# --- Set script parameters --------------------------------------

noargs="-s --silent -log --log -h --help"
noargs=($noargs)
params=("$@")
opt_flags=()
opt_flags_vals=()
opt_processes=()

function setScriptParams {

    for ((i=0; i < "${#params[@]}"; i++)); do

        if [[ "${params[$i]}" =~ ^- ]]; then

            flagArg=${params[$i]}
            flagVal=""

            if [[ $((i + 1)) -lt ${#params[@]} ]] && [[ ! "${params[$((i + 1))]}" =~ ^- ]]; then
                flagVal=${params[$((i + 1))]}
            else
                flagVal=""
            fi

            for naFlag in "${noargs[@]}"; do

                if [[ ${params[$i]} == "$naFlag" ]]; then
                    flagVal=""
                    break
                fi
            done

            opt_flags+=("$flagArg")
			opt_flags_vals+=("$flagVal")

        elif [[ ! "${params[$i]}" == "$flagVal" ]]; then
            opt_processes+=(${params[$i]})
        fi

    done

} 

function execFlags {

	local flag=""
	local val=""

	for ((i=0; i < "${#opt_flags[@]}"; i++)); do

		flag="${opt_flags[$i]}"
		val="${opt_flags_vals[$i]}"

		case $flag in

			-a | --alias)
				getAliasesByInput "Entry for domain alias(es)" "$val" 1
				;;
			-pv | --phpversion)
				php_ver_input="$val"
				;;
			-log | --log)
				logEnabled=1
				;;
			-h | --help)
				optHelp=1
				;;
			-s | --silent)
				setEWIS "silent"
				;;

		esac

    done

}

function execProcesses {

	if [[ "$1" == "deploy" ]] || [[  "$1" == "dep" ]]; then

		getHelp "$1" "$2" "helpDep"
		testRemoteDns
		getDomainNameByInput "Domain Name to Deploy" "$2"
		deploy

	elif [[ "$1" == "undeploy" ]] || [[  "$1" == "undep" ]]; then

		getHelp "$1" "$2" "helpUndep"
		testRemoteDns
		getDomainNameByInput "Domain Name to Undeploy" "$2"
		unDeploy

	elif [[ "$1" == "alias" ]]; then

		getHelp $1 $2 "helpAlias"
		testRemoteDns
		
		if [[ -z "$2" ]]; then

			echo ""
			listAllAliases

		elif [  "$2" == "add" ]; then

			echo ""
			getAliasesByInput "Entry for domain alias(es)" "$3" 1
			getDomainNameByInput "Domain name for aliases to be added" "$4"
			addAliases
			
		elif [  "$2" == "remove" ]; then
		
			echo ""
			getAliasesByInput "Entry for Alias(es)" "$3" 1
			getDomainNameByInput "Domain name for domain aliases to be removed from" "$4"
			removeAliases
		
		elif [  "$2" == "info" ]; then
		
			echo ""
			getDomainNameByInput "Domain name to get alias information" "$3"
			listAliasesByDomainName

		fi

	elif [[ "$1" == "dns" ]]; then

		getHelp "$1" "$2" "helpDns"
		testRemoteDns

		if [[ -z "$2" ]]; then

			# List All DNS Entries
			listInternalDnsEntries
			listRemoteDnsEntries

		elif [  "$2" == "add" ]; then
		
			getDomainNameByInput "Entry for internal and LAN DNS" "$3"
			_addHostEntry $domain_name
			_addDnsEntry $domain_name
			_dnsReload
			
		elif [  "$2" == "remove" ]; then
		
			getDomainNameByInput "Entry for internal and LAN DNS" "$3"
			_removeHostEntry $domain_name
			_removeDnsEntry $domain_name
			_dnsReload
			
		elif [  "$2" == "internal" ]; then
		
			if [[ -z "$3" ]]; then

				# List All Internal DNS Entries
				listInternalDnsEntries
		
			elif [  "$3" == "add" ]; then
			
				getDomainNameByInput "Entry for internal DNS" "$4"
				_addHostEntry $domain_name
				
			elif [  "$2" == "remove" ]; then
		
				getDomainNameByInput "Entry for internal DNS" "$4"
				_removeHostEntry $domain_name
				
			fi
					
		elif [  "$2" == "lan" ]; then
		
			if [[ -z "$3" ]]; then

				# List All LAN DNS Entries
				listRemoteDnsEntries
		
			elif [  "$3" == "add" ]; then
			
				getDomainNameByInput "Entry for LAN DNS" "$4"
				_addDnsEntry $domain_name
				_dnsReload
				
			elif [  "$2" == "remove" ]; then
		
				getDomainNameByInput "Entry for LAN DNS" "$4"
				_removeDnsEntry $domain_name
				_dnsReload
				
			fi
					
		fi

	elif [[ "$1" == *"cert"* ]]; then

		getHelp "$1" "$2" "helpCert"
		
		if [  -z "$2" ]; then
		
			listCerts

		elif [  "$2" == "renew" ]; then
		
			getDomainNameByInput "Domain name to create certificate" "$3"
			renewCert $domain_name

		elif [[  "$2" == *"cre"* ]]; then
		
			getDomainNameByInput "Domain name to create certificate" "$3"
			makeCert $domain_name

		elif [[  "$2" == *"del"* ]]; then
		
			getDomainNameByInput "Domain name to delete certificate" "$3"
			delCert $domain_name
		else
			msgErr "Command not found: \"$2\""
			helpCert
		fi

	elif [[ "$1" == "php" ]]; then

		getHelp "$1" "$2" "helpPhp"

		if [[ -z "$2" ]]; then

			getHelp "$1" "$2" "helpPhp"

		elif [  "$2" == "info" ]; then
		
			getDomainNameByInput "Domain name to get php info" "$3"
			#phpInfo

		elif [[ "$2" == *"ver"* ]]; then
		
			if [[ -z "$3" ]] || [[ -z "$4" ]]; then
		
				getDomainNameByInput "Domain name to get php version" "$3"
				writePhpVersion
				msgInfo " "
	
			else
				
				getDomainNameByInput "Domain name to change php version" "$3"

				php_ver_input="$4"
				setVhostPhpVersion
			fi

		else

			msgErr "Command not found: \"$2\""
			helpPhp
		fi

	elif [[ "$1" == "info" ]]; then

		testRemoteDns
		vhost_listAll
		listInternalDnsEntries
		listRemoteDnsEntries

	elif [[ "$1" == "help" ]] || [[  "$1" == "-h" ]] || [[  "$1" == "--help" ]] || [[ -z "$3" ]]; then
		helpMain
	else
		echo ""
		statErr "Command not found: \"$1\""
		helpMain

	fi
}

# --- Help -------------------------------------------------------

function getHelp {

	if [[ "$optHelp" -eq 1 ]] || [[  "$2" == "-h" ]] || [[  "$2" == "--help" ]] || [[  "$2" == "help" ]]; then

		fun="$3"
		$fun
		
		exitScript 0
	fi
}

function helpMain {

	echo -e "Usage: $scname.sh <command> [options]"
	echo -e ""
    echo -e "Commands:"
	echo -e ""
    echo -e "$fgb_ register|reg     $_e   Register a domain."
    echo -e "$fgb_ unregister|unreg $_e   Unregister a domain."
    echo -e "$fgb_ dns              $_e   Manage DNS entries."
    echo -e "$fgb_ certificate|cert $_e   Manage certificates."
    echo -e "$fgb_ php              $_e   Manage PHP settings."
    echo -e "$fgb_ info             $_e   Display all entries."
    echo -e "$fgb_ help             $_e   Display this help message."
	echo -e ""
    echo -e "For more information on each command, use:"
	echo -e "$scname.sh <command> -h | --help | help"
	echo -e ""
}

# --- Main -------------------------------------------------------

# Scroll terminal to script start
clear -x

##################################################################
echo -e "
$bblu_                                                             $_e
$bblu_  Site Deployment Utility for Local Development Environment  $_e
$bblu_  v$scvers - Cihan Tuncer                                      $_e
$bblu_                                                             $_e
$bblu_  For instructions, use \"$scname --help\" command.           $_e
$bblu_                                                             $_e
"
##################################################################

# Get options
optHelp=0

checkDependencies
getServerPhpVersions
setScriptParams
execFlags
execProcesses "${opt_processes[@]}"

echo ""

exitScript 0