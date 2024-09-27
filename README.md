# InitSite - Automated Apache PHP Websites For Your Local Network Development Environment

**InitSite** is a bash script that allows you to easily create and manage ssl-enabled Apache websites with different php versions in your local network development environment.

<br/>

## Features
- Automated web site deployment/undeployment with ssl, multi-php version, local dns redirection support.
- Easily add or remove domain aliases.
- Manage DNS records for internal DNS and local DNS servers.
- Generate/renew/delete certificates for domain.
- Get all infos about:
    - Enabled sites on the server.
    - Domain redirections in internal and local dns server records.
    - Installed php versions on the server.
    - Assigned aliases for domains

<br/>

## An Example

```
> initsite deploy mysite.home --alias "mysite.loc my.internal" --phpversion "8.3"
```
1) Creates the vhost for "mysite.home" with "mysite.loc" and "my.internal" aliases.
2) Generates and configures SSL certificates *(Optional)*.
3) Sets the PHP version to 8.3 *(Optional)*.
4) Updates DNS and internal host records.
5) Activates the site and tests HTTP/HTTPS requests *(Optional)*.
6) Enables mysite.home website and tests http, https requests on the server.

<br>

### **For detailed usage information see [Usage Examples](https://github.com/cihantuncer/InitSite/wiki/Usage-Examples) on Wiki**

<br>

## Prerequisites
Before using **InitSite**, ensure that the following dependencies are installed:

- [Apache](https://httpd.apache.org/) *(1)* 
- [PHP](https://www.php.net/) *(1)*
- [PHP-FPM](https://php-fpm.org/) for multi-php version usage. *(2)*
- DNS service (e.g., [DNSMasq](https://thekelleys.org.uk/dnsmasq/doc.html)) for local domain redirections. *(2)*
- [Mkcert](https://github.com/FiloSottile/mkcert) for certificate generation. *(2)*

*(1):Required for basic functionality*
*(2):Optional but recommended for full feature set*

See [Notes](https://github.com/cihantuncer/InitSite?tab=readme-ov-file#notes) for more information about dependencies.

<br>

## Installation

### Auto
Copy & paste code below to your terminal, hit enter.

```
src="https://api.github.com/repos/cihantuncer/initsite/releases/latest"; command -v curl &>/dev/null || { echo -e "\nError: 'curl' is not installed. Please install it and try again.\n"; exit 1; }; command -v tar &>/dev/null || { echo -e "\nError: 'tar' is not installed. Please install it and try again.\n"; exit 1; }; dURL=$(curl --silent $src | grep '"browser_download_url":' | sed -E 's/.*"([^"]+)".*/\1/'); fName=$(basename "$dURL"); curl --silent -k -L -o "$fName" "$dURL" && [ -f "$fName" ] && tar -xf "$fName" && sudo bash "./initsite/initsite.sh" setup || echo -e "\nInitSite script could not be downloaded.\n"

```

### Manual
1) Download initsite.tar and extract initsite folder to a directory on your server.
2) Run `chmod +x /path/to/initsite/initsite.sh` command to make the script executable.
3) Run `sudo ln -s /path/to/initsite/initsite.sh /usr/bin/initsite` to run the script using just its name.

<br>

## Commands

| Command             | Arguments                 | Description                                           |
|---------------------|---------------------------|-------------------------------------------------------|
| deploy              | domain.name               | Deploys site.                                         |
| undeploy            | domain.name               | Undeploys site.                                       |
| alias               | <empty>                   | Shows aliases for all enabled sites.                  |
| alias add           | "alias(es)" domain.name   | Adds provided aliases to <domain.name>.               |
| alias remove        | "alias(es)" domain.name   | Removes provided aliases from <domain.name>.          |
| alias info          | domain.name               | Shows aliases for <domain.name>.                      |
| dns                 | <empty>                   | Shows all internal, lan dns entries.                  |
| dns add             | domain.name               | Adds <domain.name> to internal, lan dns records.      |
| dns remove          | domain.name               | Removes <domain.name> from internal, lan dns records. |
| dns internal        | <empty>                   | Shows all internal dns entries.                       |
| dns internal add    | domain.name               | Adds <domain.name> to internal dns records.           |
| dns internal remove | domain.name               | Removes <domain.name> from internal records.          |
| dns lan             | <empty>                   | Shows all lan dns entries.                            |
| dns lan add         | domain.name               | Adds <domain.name> to lan dns records.                |
| dns lan remove      | domain.name               | Removes <domain.name> from lan records.               |
| cert                | <empty>                   | Shows all generated certificates for enabled sites.   |
| cert renew          | domain.name               | Renews certificate for <domain.name>                  |
| cert create         | domain.name               | Generates certificate for <domain.name>               |
| cert delete         | domain.name               | Deletes certificate for <domain.name>                 |
| php ver             | domain.name               | Shows current php version for <domain.name>           |
| php ver             | domain.name phpvers       | Changes php version of <domain.name> to provided ver. |
| info                | <empty>                   | Gets information for all enabled sites.               |
| help                | <empty>                   | Shows help.                                           |

## Flags

| Flag               | Arguments                 | Description                                 |
|--------------------|---------------------------|---------------------------------------------|
| -a, --alias        | "alias1.name alias2.name" | Provides alias(es) for related processes.   |
| -pv, --phpversion  | php version e.g., "8.3"   | Provides php version for related processes. |
| --log              | <empty>                   | Writes logs to a file in script path.       |
| -h, --help         | <empty>                   | Get help for selected command.              |

## Settings.conf

Detailed information about the predefined settings is available in the settings.conf file. Please read it carefully and change it according to your needs.   

### See [settings.conf](https://github.com/cihantuncer/InitSite/wiki/Setting.conf) on Wiki

#### For detailed usage information, see [Usage Examples](https://github.com/cihantuncer/InitSite/wiki/Usage-Examples) on Wiki

<br>

## Notes

### About Local Domain Extensions
You can use any domain extensions for local dns entries, but most TLD extensions (such as .com, .net) may be refused by your browser, os or router for security reasons ([See](https://bugdrivendevelopment.net/browser-ignore-internal-dns)).

Also do not use ".local" extension, it's reserved for mDNS on most systems ([See](https://community.veeam.com/blogs-and-podcasts-57/why-using-local-as-your-domain-name-extension-is-a-bad-idea-4828)).

It's better to use extensions that aren't reserved by authorities. **Fictitious domain extensions are the best.**

### About Dependencies
- Only Apache and PHP are required. The other components are optional, but if you don't install them, you won't be able to use the related features. However, it's recommended to install them.

- PHP-FPM is only necessary if you're managing multiple PHP version., [This guide](https://shape.host/resources/how-to-install-multiple-versions-of-php-on-debian-with-ispconfig) is quite helpful (following up to Step 4 is enough). The steps are similar for most distros and PHP versions.

- Mkcert can likely be installed easily from your distro's repositories. You can find detailed installation and setup instructions on the [Mkcert GitHub page](https://github.com/FiloSottile/mkcert). Here's a quick summary:
    - Install `mkcert`.
    - Run `sudo mkcert -install` to generate the rootCA.pem and key files as root (since InitSite creates certificates as root).
    - Use `sudo mkcert -CAROOT` to find the rootCA.pem folder. It's usually located in `/root/.local/share/mkcert`.
    - Import the "rootCA.pem" file on all the devices you use in your local development environment. See [this guide](https://www.bounca.org/tutorials/install_root_certificate.html) for more details.

- I use DNSmasq as the DNS server in my local network, but you can use any DNS server you prefer. The basic steps are:
    - Install a DNS server on a device in your local network (e.g., your router, Raspberry Pi, or PC—this could even be your web server). The DNS server should be accessible via SSH.
    - Set the local DNS server's IP address as the primary DNS for the devices in your development environment. The easiest way to do this is by changing the DNS settings on your local network router. This way, you won't have to change DNS settings on each device individually.
    - Adjust the DNS settings in the `initsite/settings.conf` file according to your network configuration.
    - For DNSmasq, [this guide](https://community.zextras.com/how-to-install-your-dns-server-using-dnsmasq/) will be helpful.

<br>

## TODO
New features are coming soon...