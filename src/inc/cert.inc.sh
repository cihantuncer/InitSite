#!/bin/bash

certificate_certName=""
certificate_keyName=""
certificate_certFile=""
certificate_keyFile=""
certificate_OK=0

# Certification help docs
function helpCert {

    echo -e "Help for command: $fgb_ certificate|cert $_e"
	echo -e "-------------"
	echo -e "Manages certificates for provided domain."
	echo -e ""
    echo -e "Usage: $scname.sh $fgb_""certificate|cert $fgy_[renew|create|delete] $_e <domain.name> "
	echo -e ""
	echo -e "> $scname.sh certificate|cert                      : Shows all certificates."
	echo -e "> $scname.sh certificate|cert renew  <domain.name> : Renews certificate for provided domain."
	echo -e "> $scname.sh certificate|cert create <domain.name> : Creates certificate for provided domain."
	echo -e "> $scname.sh certificate|cert delete <domain.name> : Deletes certificate for provided domain."
	echo -e ""

}

# Creates certificates for domain name (and aliases if provided) input.
function makeCert {
   
	if [[ $certificate_generate == 1 ]]; then

		local domain_entries="$1"

		if [[ -z  "$domain_entries" ]]; then
			local domain_entries="$domain_name *.$domain_name $domain_aliases_txt $domain_aliases_txt_wc"
		fi

		echo ""
		msgInfo "_Generating self-signed certificate..._"
	
		certificate_certName="$domain_name-cert.pem"
		certificate_keyName="$domain_name-key.pem"
		
		if [ ! -d $certificate_certsDir ]; then

			mkdir -p $certificate_certsDir
		fi

		if [ ! -d $certificate_keysDir ]; then

			mkdir -p $certificate_keysDir
		fi

		certificate_certFile="$certificate_certsDir"/"$certificate_certName"
		certificate_keyFile="$certificate_keysDir"/"$certificate_keyName"

		if [[ $EWIS == "silent" ]]; then
			mkcert -cert-file "$certificate_certFile" -key-file "$certificate_keyFile" $domain_entries 2> /dev/null
		else
			mkcert -cert-file "$certificate_certFile" -key-file "$certificate_keyFile" $domain_entries 
		fi

		if [ $? -eq 0 ]; then
			statSucc "Certificate for $domain_name (and aliases) generated successfully."
			certificate_OK=1
		else
			statErr "Certificate not generated for $domain_name. Error(s) occured."
			certificate_OK=0
		fi
	fi
}

# Deletes certificates for domain name input.
function delCert {
   
	echo ""
	msgInfo "_Deleting certificates for $domain_name _";

	certificate_certName="$domain_name""-cert.pem"
	certificate_keyName="$domain_name""-key.pem"


	if [ -f "$certificate_certsDir/$certificate_certName" ]; then
	
		rm -f "$certificate_certsDir/$certificate_certName"
		statSucc "Cert file deleted."
		
	else 
		statInfo "Cert file not exists."
	fi
	
	if [ -f "$certificate_keysDir/$certificate_keyName" ]; then
	
		rm -f "$certificate_keysDir/$certificate_keyName"
		statSucc "Key file deleted."
		
	else 
		statInfo "Key file not exists."
	fi
	
	statSucc "Certificate(s) deleted."

}

# Creates certificates for domain name (and aliases if provided) input.
function renewCert {

	if [[ $certificate_generate == 1 ]]; then

		delCert
		makeCert "$@"

		if [ $certificate_OK -eq 0 ]; then

			statErr "Error(s) occured during new certificate generation for $domain_name. Nothing changed. Exiting..."
			echo ""
			exitScript 1

		else

			local vhostFile="$apache_sitesAvailableDir/$domain_name.conf"

			if [ ! -f $vhostFile ]; then

				msgWarn "No vhost file found to update certificate.($vhostFile)"

			else

				local certFile="$certificate_certsDir/$certificate_certName"
				local certKey="$certificate_keysDir/$certificate_keyName"

				vhost_updateCertificate "$certFile" "$certKey" "$vhostFile"

				if [ $? -eq 0 ]; then
					msgSucc "Certificate parameters in vhost file are updated ($vhostFile)."
				else
					msgWarn "Certificate parameters could not be updated. Please inspect vhost config file."
					msgWarn "$vhostFile"
				fi
			fi

		fi

	fi
}

# Lists certificate files in certificates folder.
function listGeneratedCerts {

	echo ""
	echo "Generated Certificate Files"
	echo "---------------------------"

	for file in $certificate_certsDir/*; do
		echo "> Cert File: $file"
	done

	for file in $certificate_keysDir/*; do
		echo "> Key File : $file"
	done

	echo ""
	echo "---------------------------"
	echo ""


}

# Lists certificates for enabled sites
function listVHostCerts {
	
	echo "Certificates in VHost Files"
	echo "---------------------------"

	for file in $apache_sitesAvailableDir/*; do

		filename=$(basename "$file")

		if [[ $filename == "000-default.conf" ]] || [[ $filename == "default-ssl.conf" ]]; then
			continue
		fi

		echo ""
		echo "$file"

		cert_line=$(grep -i "SSLCertificateFile" "$file")
		if [[ -n $cert_line ]]; then
			cert_file=$(echo "$cert_line" | awk '{$1=""; print $0}' | xargs)
		fi

		# SSLCertificateKeyFile yolunu bulur ve birleştirir
		key_line=$(grep -i "SSLCertificateKeyFile" "$file")
		if [[ -n $key_line ]]; then
			key_file=$(echo "$key_line" | awk '{$1=""; print $0}' | xargs)
		fi

		# Eğer değişken kullanılıyorsa, değişkenin değerini bul
		if [[ $cert_file == \$* ]]; then
			var_name=${cert_file:2:-1}
			cert_file=$(grep -E "^Define $var_name" "$file" | awk '{print $3}')
		fi

		if [[ $key_file == \$* ]]; then
			var_name=${key_file:2:-1}
			key_file=$(grep -E "^Define $var_name" "$file" | awk '{print $3}')
		fi

		if [ -n "$cert_file" ]; then
			echo -e "> Cert File: $cert_file"
		else
			echo -e "> Cert File: $fgr_ Not Found$_e"
		fi

		if [ -n "$key_file" ]; then
			echo -e "> Key File : $key_file"
		else
			echo -e "> Key File : $fgr_ Not found$_e"
		fi
	done
	echo ""
	echo "---------------------------"


}

# listVHostCerts + listVHostCerts
function listCerts {

	listVHostCerts
	echo ""; echo ""
	listGeneratedCerts
}