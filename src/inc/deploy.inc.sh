#!/bin/bash

# Deploy help docs
function helpDep {

	echo ""
	echo -e "Help for command: $fblu_ deploy|dep $_e"
	echo ""
	echo -e "$fylw_ $und_""NOTICE $und_ $_e"
	echo -e "$fylw_ You can use any domain extensions for local dns entries, $_e"
	echo -e "$fylw_ but most TLD extensions (such as .com, .net) may be refused$_e"
	echo -e "$fylw_ by your browser, os or router for security reasons.$_e"
	echo -e "$fylw_ (see https://bugdrivendevelopment.net/browser-ignore-internal-dns) $_e"
	echo -e "$fylw_ Also do not use \".local\" extension, it's reserved for mDNS on most linux systems.$_e"
	echo -e "$fylw_ (see https://community.veeam.com/blogs-and-podcasts-57/why-using-local-as-your-domain-name-extension-is-a-bad-idea-4828) $_e"
	echo -e "$fylw_ It is better to use extensions that are not reserved by the authorities.$_e"
	echo ""
 	
	echo -e "Deploys provided domain name (and aliases, if provided) to local development environment."
	echo -e ""
    echo -e "Usage  : $scname.sh $fblu_""deploy|dep $fylw_<domain> $_e"
	echo -e "Example: $scname.sh deploy example.com"
	echo -e ""
	echo -e "Usage  : $scname.sh $fylw_-a 'alias1.name alias2.name' $fgb_""deploy|dep $fylw_<domain> $_e"
	echo -e "Example: $scname.sh -a 'example.loc ex.test' deploy example.home"
	echo -e ""
}

# Undeploy help docs
function helpUndep {

	echo -e ""
    echo -e "Help for command: $fblu_ undeploy|undep $_e"
	echo -e "-------------"
	echo -e "Undeploys provided domain name (and aliases, if provided) from local development environment."
	echo -e ""
    echo -e "Usage  : $scname.sh $fblu_""undeploy|undep $fylw_<domain> $_e"
	echo -e "Example: $scname.sh undeploy example.com"
	echo -e ""
	echo -e "Usage  : $scname.sh $fylw_-a 'alias1.name alias2.name' $fblu_""undeploy|undep $fylw_<domain> $_e"
	echo -e "Example: $scname.sh -a 'example.loc ex.test' undeploy example.home"
	echo -e ""
}

# Deploys site for provided domain name via input
function deploy {

	makeCert
	vhost_generate
	enableSite
}

# Undeploys site for provided domain name via input
function unDeploy {

	local vhostFile="$apache_sitesAvailableDir/$domain_name.conf"
	local aliases=$(vhost_getParam "ServerAlias" "$vhostFile")

	setAliases "$aliases"

	delCert
	removeHostEntry
	removeDnsEntry
	disableSite
}


