#!/bin/bash

dns_authPubConn=0
dns_authPassConn=0
dns_reloaded=0
dns_restarted=0
dns_restartMaxRetry=2

# Dns Help Docs
function helpDns {

	echo -e ""
    echo -e "Help for command: $fgb_ dns $_e"
	echo -e "-------------"
	echo -e "Manages DNS entries of provided domain name."
	echo -e ""
    echo -e "Usage: $scname.sh $fgb_""dns $fgy_[add|remove|internal [add|remove]|lan [add|remove]] $_e <domain.name> "
	echo -e ""
	echo -e "> $scname.sh dns           : Lists all internal and LAN hostname entries."
	echo -e "> $scname.sh dns internal  : Lists all internal hostname entries."
	echo -e "> $scname.sh dns lan       : Lists all LAN hostname entries."
	echo -e ""
	echo -e "> $scname.sh dns add <domain.name>           : Adds domain to internal and LAN hostname entries."
	echo -e "> $scname.sh dns internal add <domain.name>  : Adds domain to internal hostname entries."
	echo -e "> $scname.sh dns lan add <domain.name>       : Adds domain to LAN hostname entries."
	echo -e ""
	echo -e "> $scname.sh dns remove <domain.name>           : Removes domain from internal and LAN hostname entries."
	echo -e "> $scname.sh dns internal remove <domain.name>  : Removes domain from internal and LAN hostname entries."
	echo -e "> $scname.sh dns lan remove <domain.name>       : Removes domain from internal and LAN hostname entries."
	echo -e ""
}

# --- Internal Hostnames ---

# Adds provided domain entry to hosts file.
# Param(1) : ["domain name"] 

function _addHostEntry {

	if [ -n "$(grep $1 $hosts_file)" ]; then
    
    	statInfo "$1 entry already in $hosts_file, skipped.";
    
    else
    
        echo "127.0.0.1	$1" >> $hosts_file
    	echo "127.0.0.1	www.$1" >> $hosts_file
        
		if [ -n "$(grep $1 $hosts_file)" ]; then
    
        	statSucc "$1 is added to $hosts_file"
        
    	else
    		statErr "$1 could not be added to $hosts_file"
    	fi
    
    fi
}

# Adds domain and aliases provided by user input to internal DNS records.
function addHostEntry {
    
    echo ""
    msgInfo "_Adding $domain_name entry (and aliases) to $hosts_file _"
    
    _addHostEntry $domain_name

    if (( ${#domain_aliases[@]} )); then
	    
		for alias in "${domain_aliases[@]}"; do
		    _addHostEntry $alias
		done
	fi
}

# Removes domain entry from hosts file.
# Param(1) : ["domain name"] 

function _removeHostEntry {

	if [ -n "$(grep $1 $hosts_file)" ]; then
    
        statInfo "$1 entry found in $hosts_file";
        
        sed -i".bak" "/$1/d" $hosts_file
        
        if [ -n "$(grep $1 $hosts_file)" ]; then
    
        	statErr "$1 entry could not be removed from $hosts_file";
        
 	 	else
         	 
       		statSucc "$1 entry removed from $hosts_file";
  		fi
        
    else
        statInfo "$1 was not found in $hosts_file, skipped.";
    fi
}

# Removes aliases provided by user input or domains with other extensions
# with the same name as the domain from internal DNS records.

function _removeHostAliasEntries {

		for domain in "${domain_aliases[@]}"; do

			_removeHostEntry "$domain"
		done

	#else

		#sed -i "/\(\|www\.\)$domain_name_base\.[a-zA-Z0-9]\+/d" $hosts_file

   		#msgInfo "Entries with various extensions of \"$domain_name_base\", if any, have been deleted."

}

# _removeHostEntry + _removeHostAliasEntries
function removeHostEntry {
        
    echo ""
	msgInfo "_Removing $domain_name (and aliases) entry from $hosts_file _";
    
    _removeHostEntry "$domain_name"
    _removeHostAliasEntries
	
}

# Lists internal DNS records.
function listInternalDnsEntries {

	echo ""
	echo "Enabled Internal Hostnames"
	echo "-----------------"
	  
    echo "$(cat $hosts_file)"
	
	echo "-----------------"
    echo ""  
}

# --- Dns Server Hostnames ---

# Reloads DNS service
function _dnsReload {

	if [[ $dns_authPubConn == 1 ]]; then

		ssh $dns_user@$dns_ip -p $dns_port $dns_reloadAction

	elif [[ $dns_authPassConn == 1 ]]; then

		sshpass -p $dns_pass ssh $dns_user@$dns_ip -p $dns_reloadAction
	fi

	if [ $? -eq 0 ]; then
		statSucc "DNS service $dns_serviceName reloaded."
	else
		statWarn "DNS service $dns_serviceName could not be reloaded."
	fi

}

# Searches provided domain name entries in the remote DNS records.
# Param(1) : ["domain name"] 
# Returns : notfound|found

function _findDnsEntry {

    local infile=""
	local rcomm="if [ -n \"\$(grep $1 $dns_hostsFile)\" ]; then echo \"entryfound\"; else echo \"entrynotfound\"; fi"

	if [[ $dns_authPubConn == 1 ]]; then
		infile=$(ssh $dns_user@$dns_ip -p $dns_port $rcomm)
	elif [[ $dns_authPassConn == 1 ]]; then
		infile=$(sshpass -p $dns_pass ssh $dns_user@$dns_ip -p $dns_port $rcomm)
	fi

	echo $infile
}

# Adds provided domain name entry to the remote DNS records.
# Param(1) : ["domain name"] 

function _addDnsEntry {

	local entry1="$webserver_ip	$1"
    local entry2="$webserver_ip	www.$1"

	local infile=$(_findDnsEntry $1)

    if [  $infile == "entryfound" ]; then
     
    	statInfo "$1 entry already in dns records, skipped.";
        
	else

		local rcomm=" echo $entry1 >> $dns_hostsFile; echo $entry2 >> $dns_hostsFile"

		if [[ $dns_authPubConn == 1 ]]; then
			ssh $dns_user@$dns_ip -p $dns_port $rcomm
		elif [[ $dns_authPassConn == 1 ]]; then
			sshpass -p $dns_pass ssh $dns_user@$dns_ip -p $dns_port $rcomm
		fi

 		local added=$(_findDnsEntry $1)
      
        if [ "$added" == "entryfound" ]; then
     
    		statSucc "$1 added to dns records ($dns_hostsFile)."

		else
    
			statErr "$1 could not be added to dns records ($dns_hostsFile)."
        
		fi

	fi
}

# Adds provided domain name entry to the remote DNS records.
# Param(1) : ["domain name"] 

function addDnsEntry {

	if [[ $dns_server == 1 ]]; then

		echo ""
		msgInfo "_Adding $domain_name entry (and aliases) to dns records ($dns_hostsFile)..._"
	    
	   	_addDnsEntry $domain_name

	   	if (( ${#domain_aliases[@]} )); then
	    
			for alias in "${domain_aliases[@]}"; do
			    _addDnsEntry $alias
			done
		fi
	   
	    _dnsReload 

	fi
}

# Removes provided domain name entry from the remote DNS records.
# Param(1) : ["domain name"] 

function _removeDnsEntry {

    local infile=$(_findDnsEntry $1)
    
    if [ "$infile" == "entryfound" ]; then
    
    	statInfo "$1 entry found in dns records ($dns_hostsFile).";
    
    	local rcomm="if [ -n \"\$(grep $1 $dns_hostsFile)\" ]; then sed -i\".bak\" \"/$1/d\" $dns_hostsFile; fi"

    	if [[ $dns_authPubConn == 1 ]]; then
			ssh $dns_user@$dns_ip -p $dns_port $rcomm
		elif [[ $dns_authPassConn == 1 ]]; then
			sshpass -p $dns_pass ssh $dns_user@$dns_ip -p $dns_port $rcomm
		fi

	    local deleted=$(_findDnsEntry $1)
	
	     if [ "$deleted" == "entryfound" ]; then
	
	        statErr "$1 could not be removed from dns records ($dns_hostsFile)."
	
	     elif [ "$deleted" == "entrynotfound" ]; then
	
	        statSucc "$1 removed from dns records ($dns_hostsFile)."
	     fi
    
    elif [ "$infile" == "entrynotfound" ]; then
    
    	statInfo "$1 entry not found in dns records ($dns_hostsFile), skipped."
    
    fi 
}

# Removes aliases provided by user input or domains with other extensions
# with the same name as the domain from remote DNS records.

function _removeDnsAliasEntries {

	#if (( ${#domain_aliases[@]} )); then
	
		for domain in "${domain_aliases[@]}"; do

			_removeDnsEntry "$domain"
		done

	#else

		#local rcomm="sed -i \"/\(\|www\.\)$domain_name_base\.[a-zA-Z0-9]\+/d\" $dns_hostsFile"

		#if [[ $dns_authPubConn == 1 ]]; then
			#ssh $dns_user@$dns_ip -p $dns_port $rcomm
		#elif [[ $dns_authPassConn == 1 ]]; then
			#sshpass -p $dns_pass ssh $dns_user@$dns_ip -p $dns_port $rcomm
		#fi

		#msgInfo "Entries with various extensions of \"$domain_name_base\", if any, have been deleted."

	#fi
}

# _removeDnsEntry + _removeDnsAliasEntries
function removeDnsEntry {
    
	if [[ $dns_server == 1 ]]; then

	    echo ""
		msgInfo "_Removing $domain_name (and aliases) from dns records ($dns_hostsFile)..._"
	    
		_removeDnsEntry $domain_name
		_removeDnsAliasEntries

	    _dnsReload

	fi
}

# Checks remote DNS service status
function testDnsService {

	local silent=$1

	if [[ "$dns_server" == "1" && "$dns_serviceName" ]]; then

		local serviceCom="command -v $dns_serviceName >/dev/null 2>&1 && echo 1 || echo 0"
		local stateCom="pidof $dns_serviceName >/dev/null 2>&1 && echo 1 || echo 0"

		local succ="$dns_serviceName is running on the remote DNS server."
		local warn1="$dns_serviceName exists but not running on the remote DNS server."
		local warn2="$dns_serviceName does not exist on the remote DNS server."

		if [[ ! -z "$dns_pass"  ]]; then

			local dnsSvc=$(sshpass -p "$dns_pass" ssh "$dns_user@$dns_ip" -p "$dns_port" "$serviceCom")

			if [[ "$dnsSvc" == "1" ]]; then

				local dnsSvcState=$(sshpass -p "$dns_pass" ssh "$dns_user@$dns_ip" -p "$dns_port" "$stateCom" )

				if [[ "$dnsSvcState" == "1" ]]; then
					msgSucc $succ
				else
					msgWarn $warn1
				fi
			else
				msgWarn $warn2
			fi

		else

			local dnsSvc=$(ssh "$dns_user@$dns_ip" -p "$dns_port" "$serviceCom")
 
			if [[ "$dnsSvc" == "1" ]]; then
			
				local dnsSvcState=$(ssh "$dns_user@$dns_ip" -p "$dns_port" "$stateCom" )

				if [[ "$dnsSvcState" == "1" ]]; then
					msgSucc $succ
				else
					msgWarn $warn1
				fi
			else
				msgWarn $warn2
			fi
		fi
	
	fi
	
}

# Tests remote DNS ssh connection
function testRemoteDns {

	silent=$1

	if [[  "$dns_server" == "1" ]]; then

		local sshconn=""

		if [[ ! -z "$dns_pass"  ]]; then
			
			sshpass -p "$dns_pass" ssh "$dns_user@$dns_ip" -p "$dns_port" "exit"

			if [ $? -eq 0 ]; then
				statInfo "Test connection successfully established to dns server ($dns_user@$dns_ip)."
			else
				dns_server=0

				statWarn "Connection couldn't established to dns server ($dns_user@$dns_ip)."
				echo  -e $fgy_"       Check remote dns server settings in settings.conf."$_e
				echo  -e $fgy_"       Remote dns update $u_ disabled $_u automatically."$_e
		
			fi
		else
			ssh $dns_user@$dns_ip -p $dns_port "exit"

			if [ $? -eq 0 ]; then

				dns_authPubConn=1

				if [[ -z $silent ]]; then
					statSucc "Test connection successfully established to dns server ($dns_user@$dns_ip)."
				fi
				
			else
				dns_server=0

				if [[ -z $silent ]]; then
					statWarn "Connection couldn't established to dns server ($dns_user@$dns_ip)."
					echo  -e $fgy_"       Check remote dns server settings in settings.conf."$_e
					echo  -e $fgy_"       Check if you have valid 'ssh public key auth' connection to dns server."$_e
					echo  -e $fgy_"       Remote dns update $u_ disabled $_u automatically."$_e
				fi

			fi
		fi
	else
		if [[ -z $silent ]]; then
			echo ""
			statInfo "Remote DNS entry update disabled.";
			echo ""
		fi
	fi
}

# Lists remote DNS records.
function listRemoteDnsEntries {

	if [[ $dns_server == 1 ]]; then

		echo ""
		echo "Enabled Remote DNS Hostnames"
		echo "-----------------"


		if [[ $dns_authPubConn == 1 ]]; then
			
			ssh $dns_user@$dns_ip -p $dns_port "echo \"\$(cat $dns_hostsFile)\""

		elif [[ $dns_authPassConn == 1 ]]; then

			sshpass -p $dns_pass ssh $dns_user@$dns_ip -p $dns_port "echo \"\$(cat $dns_hostsFile)\""
		fi
		
		echo "-----------------"
	    echo ""

	fi
}