#!/bin/bash

php_fpm=0
php_ver_default=$(php -r 'echo PHP_VERSION;')
php_ver_cfg=$php_version
php_ver_input=""
php_ver_vhost=""
php_versions=()

# Php help docs
function helpPhp {

	listPhpVersions
	echo ""
    echo -e "Help for command: $fgb_ php $_e"
	echo -e "-------------"
	echo -e "Manages php version for provided domain."
	echo -e ""
    echo -e "Usage: $scname.sh $fgb_""php $fgy_[info|version] $_e <domain.name> "
	echo -e ""
	echo -e "> $scname.sh php info <domain.name>                      : Generates php info page for provided domain."
	echo -e "> $scname.sh php version|ver <domain.name>               : Gets php version for provided domain."
	echo -e "> $scname.sh php version|ver <domain.name> <php version> : Changes php version for provided domain."
	echo -e ""
	echo -e "Example: $scname.sh php ver example.home     : Shows php version for example.home"
	echo -e "Example: $scname.sh php ver example.home 8.3 : Sets php version to 8.3 for example.home"
	echo -e ""

}

# Tests live site's php version.
function testSitePhpVersion {

	vhostFile="$apache_sitesAvailableDir/$domain_name.conf"

    if [[ ! -f $vhostFile ]]; then

        msgErr "Php version testing: $vhostFile not found."
        

    else

        local docRoot=$( vhost_getParam "DocumentRoot" "$vhostFile" )

        if [[ -n $docRoot ]]; then
        
            local testName="initsite_phptest.php"
            local testFile="$docRoot/$testName"

            if [ ! -d $docRoot ]; then

                mkdir $docRoot
                chown www-data:www-data $docRoot
            fi
           
            chmod $folder_perm $docRoot

            touch $testFile
            chmod $file_perm $testFile
            chown www-data:www-data $testFile
            truncate -s 0 $testFile

            if [[ $curl_enabled == 1 ]]; then
                echo "<?php echo phpversion(); ?>" >> $testFile
            else
                echo "<?php phpinfo(); ?>" >> $testFile
            fi

            if [ $? -eq 0 ]; then

                if [[ $curl_enabled == 1 ]]; then

                    local HTTP_PHPV=$(curl -s -k http://$domain_name/$testName)
                    local HTTPS_PHPV=$(curl -s -k https://$domain_name/$testName)

                    msgInfo "Http PHP Version: <yellow>$HTTP_PHPV"
                    msgInfo "Https PHP Version: <yellow>$HTTPS_PHPV"

                else

                    msgInfo "To view PHP details, go to the links below."
                    msgInfo "http://$domain_name/$testName"
                    msgInfo "https://$domain_name/$testName"
                fi
            fi

            if [[ $curl_enabled == 1 ]]; then
                rm -f "$docRoot/$testName"
            fi
            
        else

            msgErr "Php version testing: 'DocumentRoot' value not found in the $vhostFile"
        fi

    fi


}

# Gets php installed versions on the server
# Returns   : ["phpversion1 phpversion2 ..."]

function getServerPhpVersions {

    phps=$(update-alternatives --list php)
    
    while IFS= read -r php_path; do

        version=$(basename "$php_path" | sed 's/^php//')

		if [ ! $version == ".default" ]; then

			php_versions+=("$version")

		fi
    done <<< "$phps"
}

# Lists php installed versions on the server
function listPhpVersions {

	phpStr="Installed php versions: "

	local i=0;

    for phpv in "${php_versions[@]}"; do

		if [ $i == 0 ]; then
            phpStr+="$phpv";
        else
            phpStr+=", $phpv";
        fi

		((i++))

	done

	echo "$phpStr"
}

# Checks if provided php version is installed on the server.
# Param(1) : ["phpversion"] 
# Returns  : <empty>|["phpversion"]

function checkPhpVersion {

	phpVal=$(trim $1)
	ret=""

	if [[ "$phpVal" == "default" ]]; then

		ret="default"

	else
		for phpv in "${php_versions[@]}"; do

			if [[ $phpVal == $phpv ]]; then
				ret=$phpv
				break
			fi
		done
	fi

	echo "$ret"
}

# Shows php version in the provided vhost.conf file.
# Param(1) : ["vhost.conf path"] 

function getVhostPhpVersion {

	local vhostFile="$apache_sitesAvailableDir/$domain_name.conf"

	if [ ! -f "$vhostFile" ]; then

		statErr "No vhost file found for $domain_name in '$apache_sitesAvailableDir'. Exited..."
		exitScript 1

	else
		php_ver_vhost=$(vhost_findPhpVersion "$vhostFile")

		local defres=""

		if [[ -z "$php_ver_vhost" ]]; then
			php_ver_vhost="Default"
			defres="($php_ver_default)"
		fi

		msgInfo "Active php version for $domain_name: <yellow>$php_ver_vhost $defres"

	fi
}

# Shows php version in the vhost.conf and test live site for domain name input.
function writePhpVersion {

    msgInfo "_Getting $domain_name php version from vhost file._"
	getVhostPhpVersion
    echo ""
    msgInfo "_Testing $domain_name site live php version._"
    testSitePhpVersion
}

# Updates php version for domain name input.
function setVhostPhpVersion {

    if [[ "$php_fpm" == "1" ]]; then
        vhost_updatePhpVersion "$apache_sitesAvailableDir/$domain_name.conf"
        reloadApache
        testSitePhpVersion $domain_name
    else
        msgErr "<red>PHP-FPM</red><yellow> processor is not installed on the server. Default PHP $php_ver_default version will be used."
    fi

	
}
