# Norse
A Valheim-server management script for Linux. You cant start, stop, update and backup your valheim-server using this script.

## Dependencies
`lib32gcc1` `steamcmd`

## Install
1. Download the norse.sh script using:
`DIR=$(pwd); rm norse.sh; wget -O norse.sh https://raw.githubusercontent.com/z3orc/norse/main/norse.sh; chmod +x norse.sh; cd $DIR`


2. You will need to download the dependencies shown above using a package manager or other tools.


3. To start the setup-script just run `./norse.sh setup` and follow the instructions.


If the installation was a success, the server should start after the setup-script is finished.

---

### Backup

If you would like to keep your server somewhat safe, you can use:

`./norse.sh backup`

This will make a mirror of all your save-files and config-files and move them to the backups-directory.

You can also make the process automatic, by using:

`crontab -e`

and pasting:

`@hourly /directory/of/your/server/norse.sh backup`

This will backup your server every hour, which might use a lot of disk space.

***However, this solution will not make your server data 100-percent secure, this makes your files just a little bit more secure.***

---
