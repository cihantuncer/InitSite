#!/bin/bash

domain_name=""
domain_name_base=""
domain_aliases=()
domain_aliases_txt=" "
domain_aliases_txt_www=" "
domain_aliases_txt_wc=" "

function getDomainNameByInput {

	if [ -z "$2" ]; then

		while true; do

        	read -p "$( msg "$1: " )"  inpt

            if [ ! -z "$inpt" ]; then

            	domain_name=$inpt
                break
            fi
            
        done
    else
    	domain_name=$2
	fi

	domain_name_base="${domain_name%%.*}"
	siteRoot="$vhost_serverRootDir/$domain_name"
	siteDir="$vhost_serverRootDir/$domain_name/$vhost_siteRootFolder"
	
	#if [[ "$vhost_siteRootFolder" ]]; then
	#	siteDir="$vhost_serverRootDir/$domain_name/$vhost_siteRootFolder"
	#else
	#	siteDir="$vhost_serverRootDir/$domain_name"
	#fi

	
}

# Sets aliases space separated variables 
function setAliases {

	domains=($1)

	domain_aliases=()
	domain_aliases_txt=""
	domain_aliases_txt_www=""
	domain_aliases_txt_wc=""

	for domain in "${domains[@]}"; do
		domain_aliases+=("$domain")
		domain_aliases_txt+="$domain "
		domain_aliases_txt_www+="www.$domain "
		domain_aliases_txt_wc+="*.$domain "
	done
}

# Gets aliases by input 
function getAliasesByInput {

	forced=0
	local domains=""

	if [[ "$3" ]]; then
		forced=1
	fi

	if [[ -z "$2" ]] && [[ $forced == 1 ]]; then

		while true; do

        	read -p "$( msg "$1: " )"  inpt

            if [ ! -z "$inpt" ]; then

            	domains="$inpt"
                break
            fi
            
        done
    else
    	domains="$2"
	fi

	setAliases "$domains"
}

# Adds domain aliases for provided domain name with user input to vhost file, internal, remote DNS records.
function addAliases {
	
	local vhostFile="$apache_sitesAvailableDir/$domain_name.conf"
	
	if [ ! -f "$vhostFile" ]; then

		msgWarn "No vhost file ($vhostFile) found to update."

	else
		
		local oldAliases=$(vhost_getParam "ServerAlias" "$vhostFile")
		local vAliases=""
		local cAliases=""
		local vhostEntries=""

		for alias in $domain_aliases; do

			if [[ ! "$alias" == "$domain_name" ]] && [[ ! " ${oldAliases[*]} " =~ " ${alias} " ]]; then

			   vAliases+="$alias www.$alias "
			fi

		done

		vhostEntries=$(echo "$oldAliases $vAliases" | tr -s ' ')

		# vhost
		msgInfo "Updating vhost alias entries in vhost file."
		vhost_updateParam "ServerAlias" "$vhostEntries" "$vhostFile"

		# cert
		if [[ $certificate_generate == "1" ]]; then

			local certEntries=$(echo "$domain_name $vhostEntries" | sed 's/www/\*/g')
			msgInfo "Updating certificate entries in vhost file."
			renewCert "$certEntries"
		fi

		local hostEntries="$domain_name $vhostEntries"

		# Update internal and remote DNS records.
		for entry in ${hostEntries[@]}; do

			_addHostEntry $entry

			if [[ $dns_server == "1" ]]; then
				_addDnsEntry "$entry"
			fi

		done

		reloadApache

	fi

}

# Removes domain aliases for provided domain name from vhost file, internal, remote DNS records.
function removeAliases {
	
	local vhostFile="$apache_sitesAvailableDir/$domain_name.conf"
	
	if [ ! -f "$vhostFile" ]; then

		msgWarn "No vhost file ($vhostFile) found to update."

	else
		
		local oldAliases=$(vhost_getParam "ServerAlias" "$vhostFile")
		local vhostEntries=""
		local remEntries=""

		for alias in $domain_aliases; do

			if [[ ! "$alias" == "$domain_name" ]] && [[ " ${oldAliases[*]} " =~ " ${alias} " ]]; then

				msgInfo "Removing alias $alias from vhost file."
				oldAliases=$(echo "$oldAliases" | sed -E "s/(www\.)?$alias(\s|$)//g")
				remEntries+="$alias www.$alias "
			fi

		done

		vhostEntries=$(echo "$oldAliases" | tr -s ' ')

		if [[ -z "$vhostEntries" ]]; then
			msgInfo "No remaining aliases. Removing ServerAlias directive from vhost file."
			vhost_removeParam "ServerAlias" "$vhostFile"
		else
			msgInfo "Updating alias entries in vhost file..."
			vhost_updateParam "ServerAlias" "$vhostEntries" "$vhostFile"
		fi

		if [[ $certificate_generate == "1" ]]; then

			local certEntries=$(echo "$domain_name $vhostEntries" | sed 's/www/\*/g')

			msgInfo "Updating certificate entries in vhost file..."
			renewCert "$certEntries"
		fi


		# Update internal and remote DNS records.
		for entry in ${remEntries[@]}; do
			if [[ ! "$entry" == "$domain_name" ]]; then
				_removeHostEntry $entry

				if [[ $dns_server == "1" ]]; then
					_removeDnsEntry "$entry"
				fi
			fi
		done

		reloadApache

	fi

}

# Gets path of a temporary copy of remote DNS's hosts file
function getRemoteHostsFile {

	if [[ $dns_server == 1 ]]; then

		tempRemoteHostsPath=$(mktemp /tmp/remote_file_XXXXXX)

		if [[ $dns_authPubConn == 1 ]]; then

			ssh $dns_user@$dns_ip -p $dns_port "cat ${dns_hostsFile}" > "$tempRemoteHostsPath"

			if [ $? -eq 0 ]; then
				echo "$tempRemoteHostsPath"
			else
				rm -f "$tempRemoteHostsPath"
			fi

		elif [[ $dns_authPassConn == 1 ]]; then

			sshpass -p $dns_pass ssh $dns_user@$dns_ip -p $dns_port "cat ${dns_hostsFile}" > "$tempRemoteHostsPath"

			if [ $? -eq 0 ]; then
				echo "$tempRemoteHostsPath"
			else
				rm -f "$tempRemoteHostsPath"
			fi
		fi
	fi
}

# Lists aliases in vhost file, internal and external DNS records for provided vhost file.
# params(1) : ["domain name"]

function listAliases {

	vhostFile=$1

	local aliases=""

	file_extension="${vhostFile##*.}"
	basename_no_ext=$(basename "${vhostFile%.*}")

	if [[ ! $file_extension == "bak" ]]; then

		aliases=$(vhost_getParam "ServerAlias" "$1")
		aliases=$(echo $aliases | tr -s ' ')

		if [[ -n "$aliases" ]]; then

			echo ""
			echo Domain: $basename_no_ext
			echo ""

			echo -e "$fgb_""Aliases in $vhostFile:$_e"
			echo "$aliases"

			local inHostsFile=""
			local inDNSEntries=""
			local tempRemoteHosts=$(getRemoteHostsFile)
			
			IFS=' ' read -r -a alias_array <<< "$aliases"
			for domain in "${alias_array[@]}"; do

				if [[ ! "$domain" =~ ^www\..* ]]; then

					inHostsFile="$inHostsFile$(findStringInFile $domain $hosts_file 1 1)"

					if [[ "$tempRemoteHosts" ]]; then
					
						inDNSEntries="$inDNSEntries$(findStringInFile $domain $tempRemoteHosts 1 1)"
					fi
				fi
			done

			echo ""
			echo -e "$fgb_""Redirections in internal hosts file ($hosts_file):$_e"
			echo -e ${inHostsFile:2}

			if [ ! -z "$inDNSEntries" ]; then
				echo ""
				echo -e "$fgb_""Redirections in remote DNS hosts file ($dns_hostsFile):$_e"
				echo -e ${inDNSEntries:2}
			fi

			if [[ -e "$tempRemoteHosts" ]]; then
				rm -f "$tempRemoteHosts"
			fi

			echo ""
		
		else
			echo -e "Domain: $basename_no_ext $fgy_""No aliases found. $_e"
		fi

		echo "---------------------------"


	fi

}

# Lists aliases in vhost file, internal and external DNS records for domain name input.
function listAliasesByDomainName {

	listAliases "$apache_sitesAvailableDir/$domain_name.conf"
}

# Lists aliases in vhost file, internal and external DNS records for all enabled sites.
function listAllAliases {

	echo ""
	echo "DOMAIN ALIASES"
	echo "##############"
	echo ""
	
	for file in $apache_sitesAvailableDir/*; do

		listAliases $file
	done

	echo ""

}