#!/bin/bash

# Update Value : Replace the value in the file with the new value.
# Params       : ["old value"] ["new value"] ["target file"]

function vhost_updateVal {

	local oldValue="$1"
	local newValue="$2"
	local file="$3"

    if [[ -f "$file" ]]; then

		sed -i "s|$oldValue|$newValue|g" "$file"

		if [[ $? -eq 0 ]]; then
			msgInfo "'$oldValue' replaced with '$newValue' in $file."
		else
			msgErr "Failed to update '$oldValue' in $file."
		fi
	else
        msgErr "$file not found while trying to update $oldValue to $newValue."
    fi
}

# Update Directive : Replace the directive's value in the file with the new value.
# Params(4+) : ["<directive"] ["old value"] ["new value"] ["vhost.conf path"] [Skip values ["skipValue1"] ["skipValue2"] ...]
# Returns    : Result messages
# Examples   :

# Update <Directory /old/path> to <Directory /new/path>:
# > vhost_updateDirective "<Directory" "/old/path" "/new/path" "vhost.conf"

# Update all <Directory> blocks:
# > vhost_updateDirective "<Directory" "" "/new/path" "vhost.conf"

# Update all <Directory> blocks but skip ${SRVROOT} and cgi-bin:
# > vhost_updateDirective "<Directory" "" "/new/path" "vhost.conf" "\${SRVROOT}" "cgi-bin"

#  Update DocumentRoot, skipping existing specific directories:
# > vhost_updateDirective "DocumentRoot" "/var/www/html" "/var/www/new_site" "vhost.conf" "/srv/www" "/var/www/exclude"

function vhost_updateDirective {

    local directive="$1"
	local oldValue="$2"
	local newValue="$3"
	local file="$4"
	shift 4
	local skips=("$@")
    
    if [[ -f "$file" ]]; then

		if [[ -n "$oldValue" ]]; then
			sedPattern="s|^\(\s*${directive}\s*\)\(${oldValue}\)\(>\)|\1${newValue}\3|"
		else
			sedPattern="s|^\(\s*${directive}\s*\)\S\+\(>\)|\1${newValue}\2|"
		fi

		if [[ "${#skips[@]}" -gt 0 ]]; then

			skipRegexs=""

			for skip in "${skips[@]}"; do
				skipRegexs+="/$skip/b; "
			done

			sed -i "${skipRegexs}${sedPattern}" "$file"

		else
			sed -i "$sedPattern" "$file"
		fi

		if [[ $? -eq 0 ]]; then
			msgSucc "'${directive}' value changed to '${newValue}' in $file."
		else
			msgErr "Failed to update '${directive}' in $file."
		fi
	else
		msgErr "$file not found while trying to update '$directive's value to $newValue."
    fi


}

# Get Parameter : Get parameter's value from the vhost file.
# Params(3) : ["parameter"] ["vhost.conf path"] [get first or all 0(default)|1]
# Returns   : Found parameter values

function vhost_getParam {

    local param="$1"
    local file="$2"
    local opt="$3"
    local result=""

    if [[ -f $file ]]; then

        while read -r value; do

            value=$(echo "$value" | cut -d' ' -f2-)
            value=$(echo "$value" | sed 's/^[ \t]*//;s/[ \t]*$//')

            if [[ -n "$value" ]]; then
                if [[ "$opt" == "1" ]]; then
                    result+="$value "
                else
                    result="$value"
                    break
                fi
            fi
        done < <(grep -i "$param" "$file")
    fi

    echo "$result"
}


# Update/Add Parameter : Replace the parameter's value in the file with the new value.
# Note: if the parameter to update does not exist, adds parameter at the end of the <VirtualHost (80 or 433 or both)> block.
# Params(4) : ["parameter"] ["new value"] ["vhost.conf path"] [vhost port identifier <empty for both>|"80"|"443"]
# Examples  :

# Update/Add "ServerName" in the <VirtualHost *:80> and <VirtualHost *:443> blocks:
# > vhost_updateParam "ServerName" "mysite.com" "vhost.conf"

# Update/Add "SSLCertificateFile" in the <VirtualHost *:443> block:
# > vhost_updateParam "SSLCertificateFile" "mysite.com" "vhost.conf" "443"

function vhost_updateParam {

	local param="$1"
	local newValue="$2"
	local file="$3"
	local block="$4"

	if [ -z $block ]; then
		vhost_updateParam "$1" "$2" "$3" "80"
		vhost_updateParam "$1" "$2" "$3" "443"
	else

		local succ="'$param' parameter updated to '$newValue' in '$file'."
		local serr="SED command failed while trying to change '$param's value to $newValue."

		if [[ -f "$file" ]]; then

			if grep -q "<VirtualHost [^>]*:$block>" "$file"; then	

				if grep -q "$param" "$file"; then

					sed -i "s|^\(\s*$param\)\s\+|\1 |" "$file"
					sed -i "s|^\(\s*$param\s*\).*|\1$newValue|" "$file"

					if [[ $? -eq 0 ]]; then
						msgInfo $succ
					else
						msgErr $err
					fi
				else
					sed -i "/<VirtualHost [^>]*:$block>/,/<\/VirtualHost>/ { /<\/VirtualHost>/i\ \ \ \ $param $newValue\n}" "$file"

					if [[ $? -eq 0 ]]; then
						msgInfo $succ
					else
						msgErr $err
					fi
				fi
			else
				msgErr "Could not find <VirtualHost :$block> in '$file' while trying to change '$param's value to '$newValue'."
			fi
		else
			msgErr "\"$file\" not found."
		fi
	fi
}

# Remove Parameter : Remove all provided parameters from vhost file.
# Params(2) : ["parameter"] ["vhost.conf path"]

function vhost_removeParam {

    local param="$1" 
    local vhostFile="$2"

    if [ ! -f "$vhostFile" ]; then
        msgWarn "No vhost file ($vhostFile) found to remove parameter."
	else

		sed -i "/^\s*$param\b/d" "$vhostFile"

		if grep -q "$param" "$vhostFile"; then
			msgErr "Failed to remove $param from $vhostFile."
		else
			msgInfo "$param removed successfully from $vhostFile."
		fi

    fi
}

# Update Certificate : Update or add certificate parameters in the <VirtualHost *:443> block.
# Params(4) : ["new cert path"] ["new cert key path"] ["vhost.conf path"]

function vhost_updateCertificate {

	local newCertPath=$1
	local newCertKeyPath=$2
	local vhostFile=$3

	vhost_updateParam "SSLEngine" "on" "$vhostFile" "443"
	vhost_updateParam "SSLCertificateFile" "$newCertPath" "$vhostFile" "443"
	vhost_updateParam "SSLCertificateKeyFile" "$newCertKeyPath" "$vhostFile" "443"

}

# Find FPM PHP Sock : Find and return first/all fpm php sock value in the vhost file
# Params(2) : ["vhost.conf path"] [1 to return all found fpm php socks]
# Returns   : phpXXX-fpm.sock | "phpXXX-fpm.sock phpYYY-fpm.sock"
# Examples  :

# > vhost_findFpmSock "vhost.conf"   > "php8.3-fpm.sock"
# > vhost_findFpmSock "vhost.conf" 1 > "php8.3-fpm.sock php7.4-fpm.sock"

function vhost_findFpmSock {

	local vhostFile=$1
	local opt=$2

	local pattern=".*php.*-fpm\.sock"
	local result=""

	while IFS= read -r line; do
		if [[ $line =~ $pattern ]]; then

			if [[ $opt == 1 ]]; then
				result+="$(echo "$line" | grep -oP '(?<=/)[^/]+-fpm\.sock') "
			else
				result="$(echo "$line" | grep -oP '(?<=/)[^/]+-fpm\.sock')"
				break
			fi

		fi
	done < "$vhostFile"

	echo $result
}

# Find PHP version(s) : Find and return first/all fpm sock php version(s) in the vhost file
# Params(2) : ["vhost.conf path"] [1 to return all found php versions]
# Returns   : phpversion | "phpversion1 phpversion2"
# Examples  :

# > vhost_findPhpVersion "vhost.conf"   > "8.3"
# > vhost_findPhpVersion "vhost.conf" 1 > "8.3 7.4"

function vhost_findPhpVersion {

	local fpmSocks=( $( vhost_findFpmSock $1) )
	local opt=$2
	local result=""

	if [[ "$fpmSocks" ]]; then

		for fpm in ${fpmSocks[@]}; do

			if [[ $opt == 1 ]]; then
				result+="$(echo $fpm | grep -o -P '(?<=php).*(?=-fpm.sock)') "
			else
				result="$(echo $fpm | grep -o -P '(?<=php).*(?=-fpm.sock)')"
				break
			fi
		done
	fi

	echo $result
}

# Cleans up Empty FilesMatch blocks
# Returns   : none

function vhost_cleanUpFilesMatch {

    local vhostFile="$1"
    local tempFile=$(mktemp)
    local inBlock=0
    local blockContent=""
    local contentFound=0

    while IFS= read -r line || [[ -n "$line" ]]; do

        # Satırı kırpın ve gereksiz boşlukları kaldırın
        trimmedLine=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | sed 's/[[:space:]]\+/ /g')

        if [[ "$trimmedLine" =~ ^\<FilesMatch\ .+ ]]; then
            # <FilesMatch> bloğuna giriliyor
            inBlock=1
            blockContent="$line"$'\n'
            contentFound=0

        elif [[ "$trimmedLine" =~ ^\</FilesMatch\>$ ]]; then
            # </FilesMatch> bloğunun sonu
            blockContent+="$line"$'\n'

            # Eğer blok doluysa dosyaya yaz, boşsa atla
            if [[ $contentFound -eq 1 ]]; then
                echo -n "$blockContent" >> "$tempFile"
            fi

            # Blok sıfırlanıyor
            inBlock=0
            blockContent=""

        elif [[ $inBlock -eq 1 ]]; then
            # <FilesMatch> bloğundaki satırları ekliyoruz
            blockContent+="$line"$'\n'

            # Yorum ve boş satır dışındaki içerikler için işaretleme
            if [[ ! "$trimmedLine" =~ ^# ]] && [[ ! "$trimmedLine" =~ ^$ ]]; then
                contentFound=1
            fi

        else
            # <FilesMatch> dışında kalan satırları doğrudan dosyaya yazıyoruz
            echo "$line" >> "$tempFile"
        fi

    done < "$vhostFile"

    # Eğer blok hala açık ve doluysa dosyaya yazın
    if [[ $inBlock -eq 1 && $contentFound -eq 1 ]]; then
        echo -n "$blockContent" >> "$tempFile"
    fi

    # Geçici dosyayı orijinal dosyayla değiştir
    mv "$tempFile" "$vhostFile"

    # Dosya izinlerini ayarla
    chmod 644 "$vhostFile"
}

# Removes all fpm php socks in the vhost.
# Returns   : result messages

function vhost_removeFpmSock {

    local vhostFile="$1"
    local pattern="php.*-fpm\.sock"

    if grep -q "$pattern" "$vhostFile"; then

        sed -i "/<FilesMatch \\.php>/,/<\/FilesMatch>/ {/php.*-fpm\.sock/ {d}}" "$vhostFile"

        if [[ $? -eq 0 ]]; then
            msgDebug "Deleted fpm socket blocks in the $vhostFile file."
			msgInfo "Vhost file updated."
        else
            msgDebug "Error while deleting <FilesMatch> blocks containing fpm php sock."
			msgErr "Vhost file could not be updated."
        fi
    else
        msgDebug "No matching fpm socket block found in the '$vhostFile' file."
    fi

	vhost_cleanUpFilesMatch $vhostFile

}

# Update Fpm Php Sock : Updates all "phpXXX-fpm.sock" values with the new value in the vhost file.
# Params(2) : ["new sock value"] ["vhost.conf path"]

function vhost_updateFpmSock {

    local newSock="$1"
    local vhostFile="$2"
    local pattern="proxy:unix:[^|]*|fcgi://localhost/"
    local replacement="$newSock"

    if [[ -f "$vhostFile" ]]; then

        if grep -q "<FilesMatch \.php>" "$vhostFile"; then

            sed -i "/<FilesMatch \\.php>/,/<\/FilesMatch>/s#$pattern#$replacement#g" "$vhostFile"

            if [[ $? -eq 0 ]]; then
                msgDebug "Updated php fpm socks to '$newSock' in the $vhostFile file."
                msgInfo "Vhost file ($vhostFile) updated."
            else
                msgDebug "Error while replacing fpm sock with '$newSock' in the $vhostFile file."
                msgErr "Vhost file ($vhostFile) could not be updated."
            fi
        else
            if grep -q "<VirtualHost" "$vhostFile"; then

                sed -i "/<\/VirtualHost>/i \\    <FilesMatch \\.php>\n        SetHandler \"$newSock\"\n    </FilesMatch>\n" "$vhostFile"
                
                if [[ $? -eq 0 ]]; then
                    msgDebug "Added the new '$newSock' block to the $vhostFile file."
                    msgInfo "Vhost file ($vhostFile) updated."
                else
                    msgDebug "Error while adding the new '$newSock' block to the $vhostFile file."
                    msgErr "Vhost file ($vhostFile) could not be updated."
                fi
            else
                msgDebug "No <VirtualHost> block found in the '$vhostFile' file."
                msgErr "Vhost file ($vhostFile) could not be updated."
            fi
        fi

    else
        msgDebug "File '$vhostFile' does not exist."
    fi

}

# Get Fpm Sock Path : Find fpm sock path for provided php version
# Params(1) : ["php version"]
# Returns   : Path

function getFpmSockDir {

	local php_version=$( trim $1 )

    if [[ "$php_version" ]]; then

		local pool_config="/etc/php/${php_version}/fpm/pool.d/www.conf"

		if [[ -f "$pool_config" ]]; then

			local sock_path=$(grep -oP '^listen\s*=\s*\K.*' "$pool_config")

			if [[ -e "$sock_path" ]]; then
				echo "$sock_path"
			fi
		fi
	fi
}

# Update Php Version : Updates all fpm php versions values with the provided version.
# Params(2) : ["vhost.conf path"] [fallback to available version 0|1]

function vhost_updatePhpVersion {

	local vhostFile="$1"
	local fallback="$2"

	# Check user input
	php_ver_result=$(checkPhpVersion "$php_ver_input")

	# No or incorrect user input, use settings.config file
	if [[ ! "$php_ver_result" ]]; then

		if [[ "$fallback" == "1" ]]; then

			# Check settings.config
			php_ver_result=$( checkPhpVersion "$php_ver_cfg" )

		else

			msgErr "Provided '$php_ver_input' php version is not installed on the server."
			msgErr "Please enter one of installed php versions below"
			msgErr "or enter 'default' for server's default php version."

			msgInfo " "
			listPhpVersions
			msgInfo " "

			exitScript
		fi
	fi

	if [[ ! "$php_ver_result" ]] || [[ "$php_ver_result" == "default" ]]; then

		msgInfo "Changing php version to server's default ($php_ver_default)..."

		# Using default php version, remove FPM handlers.
		vhost_removeFpmSock "$vhostFile"
		
	else
		# Using specified php version, add/update FPM handlers.

		local sockDir=$(getFpmSockDir $php_ver_result)

		if [[ -n $sockDir ]]; then

			fpmSock="proxy:unix:$sockDir|fcgi://localhost/"

			msgInfo "Changing to php version '$php_ver_result' for $domain_name ..."

			vhost_updateFpmSock "$fpmSock" "$vhostFile"

			enableService "php$php_ver_result-fpm"
			startService "php$php_ver_result-fpm"

		else
			msgErr "$php_ver_result socket file for php '$php_ver_result' not found."
			msgErr "Make sure php$php_ver_result fpm socket file installed on the server."

		fi
	fi
}

# Generate VHOST  : Generates vhost file while domain registration
# Params(0) : 
# Returns   : Result messages

function vhost_generate {
    
    echo ""
    msgInfo "_Generating Apache vhost config for $domain_name _"
    

	# --- Check existing VHOST file -----------------

	if [ -f "$apache_sitesAvailableDir/$domain_name.conf" ]; then
            
		mv "$apache_sitesAvailableDir/$domain_name.conf" "$apache_sitesAvailableDir/$domain_name.conf.bak"
        
        if [ $? -eq 0 ]; then
	    
	    	msgInfo "$apache_sitesAvailableDir/$domain_name.conf vhost file already exists. Backupped old config as $domain_name.conf.bak."
        
    	else

          	statErr "$apache_sitesAvailableDir/$domain_name.conf vhost file cannot be created. Rolling back and exiting..."
            
            delCert
            
            echo ""
            echo "Finised unsuccessfully."
            echo ""
            
        	exitScript 
		fi
        
    else

    	touch $apache_sitesAvailableDir/$domain_name.conf
        chmod $file_perm $apache_sitesAvailableDir/$domain_name.conf
        
        if [ $? -eq 0 ]; then
	    
	    	msgInfo "$apache_sitesAvailableDir/$domain_name.conf vhost file created."
        
    	else
    		statErr "$apache_sitesAvailableDir/$domain_name.conf vhost file cannot be created. Rolling back and exiting..."
            
            delCert
            
            echo ""
            echo "Finised unsuccessfully."
            echo ""
            
        	exitScript 
		fi
    fi

	# --- Build VHOST file from template -----------------

	VHTempFile="$SCRIPT_PATH/src/vhost.template"
	confFile="$apache_sitesAvailableDir/$domain_name.conf"
	confTempFile="$confFile.template"

	cp -rf $VHTempFile $confTempFile

	if [[ -f $confTempFile ]]; then

		# --- Update certificate param -----------------

		local certificate_notice=""

		if [ $certificate_OK -eq 0 ]; then
			
			certificate_certFile="$certificate_default_certFile"
			certificate_keyFile="$certificate_default_keyFile"

			if [[ $certificate_generate == 1 ]]; then

				msgWarn "Error(s) occured during new certificate generation for domain."
				msgWarn "Server-specified default ssl certificate and key are applied."
				msgWarn "Make sure mkcert is working and $scname settings are correct."
				msgWarn "Then run command: \"$scname cert renew {{domain_name}}\""

			fi
		fi

		setEWIS "err"

		vhost_updateCertificate "$certificate_certFile" "$certificate_keyFile" "$confTempFile"

		# --- Set PHP version ----------------

		if [[ "$php_fpm" == "1" ]]; then
			vhost_updatePhpVersion "$confTempFile" 1
		else
			php_ver_input="default"
			vhost_updatePhpVersion "$confTempFile" 1
		fi

		# --- Set parameters -----------------




		vhost_updateParam "ServerName" "$domain_name" "$confTempFile"
		vhost_updateParam "ServerAlias" "www.$domain_name $domain_aliases_txt $domain_aliases_txt_www" "$confTempFile"
		vhost_updateParam "DocumentRoot" "$siteDir" "$confTempFile"
		vhost_updateDirective "<Directory" "{{SITEDIR}}" "$siteDir" "$confTempFile"

		removeEWIS

		# --- Rename template file -----------------

		mv $confTempFile $confFile
		chmod $file_perm $confFile

	fi

	if [ $? -eq 0 ]; then
	    statSucc "HTTP and HTTPS vhost configs created in $apache_sitesAvailableDir/$domain_name.conf file."
	else
	    statErr "Vhost file not created in $apache_sitesAvailableDir/$domain_name.conf file."
	fi
}

# List VHOSTs
# Params(0) : 
# Returns   : Enabled vhost list

function vhost_listAll {

	echo ""
	echo "Enabled VHosts"
	echo "-----------------"
	  
    echo "$(apache2ctl -S 2>/dev/null | grep -o -E '(port) (.*)\s' | cut -d ' ' -f 1-4 )"
	
	echo "-----------------"
    echo "" 
}

# Test Site : Creates and executes a php file for test http(s) requests.

function testSite {

    echo ""
	msgInfo "_Testing $domain_name live site_"
	echo ""

	if [ ! -d $siteRoot ]; then

    	mkdir -m $folder_perm -p $siteRoot
        chown www-data:www-data $siteRoot

    fi

    if [ ! -d $siteDir ]; then

    	mkdir -m $folder_perm -p $siteDir
        chown www-data:www-data $siteDir

    fi

	local testName="initsite_regtest.php"
	local testFile="$siteDir/$testName"

    touch "$testFile"
	truncate -s 0 "$testFile"

	if [[ $curl_enabled == 1 ]]; then
		echo "<?php echo 'regok'; ?>" >> "$testFile"
	else
		echo "<?php phpinfo(); ?>" >> "$testFile"
	fi
    
    chmod $folder_perm "$testFile"
    chown www-data:www-data "$testFile"

    if [ $? -eq 0 ]; then

		if [[ $curl_enabled == 1 ]]; then

			local HTTP_OK=$(curl -s -k "http://$domain_name/$testName")

			if [ "$HTTP_OK" == "regok" ]; then
				msgSucc "Test File: Http response ok."
			else
				msgErr "Test File: Http response failed."
			fi

			sleep 1

			local HTTPS_OK=$(curl -s -k "https://$domain_name/$testName")

			if [ "$HTTPS_OK" == "regok" ]; then
				msgSucc "Test File: Https response ok."
			else
				msgErr "Test File: Https response failed."
			fi
		else
			msgInfo "To view PHP details, go to the links below."
			msgInfo "http://$domain_name/initsite_regtest.php"
			msgInfo "https://$domain_name/initsite_regtest.php"
		fi

    else

        statErr "Test file failed. Errors occured."
    fi

    echo ""

    testSitePhpVersion
    
	if [[ $curl_enabled == 1 ]]; then

		rm -f $siteDir/initsite_regtest.php
		chmod 2770 $siteDir

	fi
}

# Enable Site : Main process for site enablement

function enableSite {

	echo ""
	msgInfo "_Enabling $domain_name..._";

	a2ensite $domain_name > /dev/null 2>&1

    if [ $? -eq 0 ]; then
       
    	statSucc "$domain_name enabled.";
        
        addHostEntry
        addDnsEntry
   		restartApache
        testSite

    else
   		statErr "$domain_name could not be enabled. Error(s) occured.";
    fi 
}

# Disable Site : Main process for site disablement

function disableSite {

    echo ""
	msgInfo "_Disabling $domain_name..._"

	a2dissite -q $domain_name

	if [ -f "$apache_sitesAvailableDir/$domain_name.conf" ]; then
    
    	rm -f $apache_sitesAvailableDir/$domain_name.conf
        statSucc "Site config file deleted."
                
	else
	    statInfo "Site config file not exists."
	fi
    
	statSucc "$domain_name disabled."
    
    reloadApache
}

# Restart Apache Service

function restartApache {

    service apache2 restart
    
    if [ $? -eq 0 ]; then
                   
        statInfo "Apache restarted."
                    
    else
    	statWarn "Apache could not be restarted. Error(s) occured."
    fi
}

# Reload Apache Service

function reloadApache {

	service apache2 reload
    
    if [ $? -eq 0 ]; then
                   
        msgInfo "Apache reloaded."
                    
    else
    	msgWarn "Apache could not be reloaded. Error(s) occured."
    fi
}
