# InitSite - Automated Apache PHP Websites For Your Local Network Development Environment

**InitSite** is a bash script that allows you to easily create and manage ssl-enabled Apache websites with different php versions in your local network development environment.

<br/>

## Features
- Automated web site deployment/undeployment with ssl, multi-php version, local dns redirection support.
- Add/remove aliases to domain.
- Add/remove DNS records for internal dns entries (your local web server) and for your local DNS server.
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
1) Creates vhost file for "mysite.home" with "mysite.loc my.internal" aliases.
2) Generates ssl certificate and key for domain and aliases (with wildcards) and defines in the vhost file. *(Optional)*
3) Creates PHP-FPM sock handler in the vhost file for using specified php version. *(Optional)*
4) Adds mysite.home, mysite.loc, my.internal, www.mysite.home, www.mysite.loc, www.my.internal redirections to the internal hosts entries.
5) Adds mysite.home, mysite.loc, my.internal, www.mysite.home, www.mysite.loc, www.my.internal redirections to the local dns server entries. *(Optional)*
6) Enables mysite.home website and tests http, https requests on the server.

<br>

### **For detailed usage information see [Usage Examples](https://github.com/cihantuncer/InitSite/wiki/Usage-Examples) on Wiki**

<br>

## Prerequisites
Before using **InitSite**, ensure that the following dependencies are installed:

- Apache. *(Mandatory)*
- PHP. *(Mandatory)*
- PHP-FPM for multi-php version usage. *(Optional)*
- DNS service (e.g., DNSMasq) for local domain redirections. *(Optional)*
- Mkcert for certificate generation. *(Optional)*

<br><br>

## Installation

### Auto (`Curl` required.)
Copy & paste code below to your terminal, hit enter.

```
src="https://api.github.com/repos/cihantuncer/initsite/releases/latest";dURL=$(curl --silent $src | grep '"browser_download_url":' | sed -E 's/.*"([^"]+)".*/\1/'); fName=$(basename "$dURL"); curl --silent -k -L -o "$fName" "$dURL" && [ -f "$fName" ] && tar -xf "$fName" && sudo bash "./initsite/initsite.sh" setup || echo -e "\nInitSite script could not be downloaded.\n"
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
| cert create         | domain.name               | Genereates certificate for <domain.name>              |
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

<br>

-----

### For detailed usage examples, see [Usage Examples](https://github.com/cihantuncer/InitSite/wiki/Usage-Examples) on Wiki

<br>