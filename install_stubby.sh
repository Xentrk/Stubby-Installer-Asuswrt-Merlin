#!/bin/sh
####################################################################################################
# Script: install_stubby.sh
# Original Author: Xentrk
# Last Updated Date: 2-February-2019
#
# Description:
#  Install the stubby DNS over TLS resolver package from entware on Asuswrt-Merlin firmware.
#  See https://github.com/Xentrk/Stubby-Installer-Asuswrt-Merlin for a description of system changes
#
# Acknowledgement:
#  Chk_Entware function provided by @Martineau. Mods made by Adamm
#  Test team: bbunge, skeal, M@rco, Jack Yaz
#  Assistance: John9527 implemented Stubby on his Fork and provided lessons learned and an example of
#              stubby.yml used in the Fork.
#  Contributors: Adamm & Jack Yaz both forked and updated the original installer to provide support
#                for HND routers. Adamm also implemented the performance improvements listed below,
#                and performed code enhancements.
#
#                Odkrys compiled Stubby for HND routers RT-AC86U, RT-AX88U, GT-AC5300 and provided
#                performance improvement suggestionns: TLS 1.3 / Cipher List / haveged
#
####################################################################################################
export PATH=/sbin:/bin:/usr/sbin:/usr/bin$PATH
logger -t "($(basename "$0"))" "$$ Starting Script Execution"
VERSION="1.0.4"
GIT_REPO="Stubby-Installer-Asuswrt-Merlin"
GITHUB_DIR="https://raw.githubusercontent.com/Xentrk/$GIT_REPO/master"
localmd5="$(md5sum "$0" | awk '{print $1}')"
remotemd5="$(curl -fsL --retry 3 "${GITHUB_DIR}/install_stubby.sh" | md5sum | awk '{print $1}')"

# Uncomment the line below for debugging
#set -x

COLOR_RED='\033[0;31m'
COLOR_WHITE='\033[0m'
COLOR_GREEN='\e[0;32m'


welcome_message () {
		while true; do
			printf '\n_______________________________________________________________________\n'
			printf '|                                                                     |\n'
			printf '|  Welcome to the %bStubby-Installer-Asuswrt-Merlin%b installation script |\n' "$COLOR_GREEN" "$COLOR_WHITE"
			printf '|  Version %s by Xentrk                                            |\n' "$VERSION"
			printf '|         ____        _         _                                     |\n'
			printf '|        |__  |      | |       | |                                    |\n'
			printf '|  __  __  _| |_ _ _ | |_  ___ | | __    ____ ____  _ _ _             |\n'
			printf '|  \ \/ / |_  | %b %b \  __|/ _ \| |/ /   /  _//    \| %b %b \            |\n' "\`" "\`" "\`" "\`"
			printf '|   /  /  __| | | | |  |_ | __/|   <   (  (_ | [] || | | |            |\n'
			printf '|  /_/\_\|___ |_|_|_|\___|\___||_|\_\[] \___\\\____/|_|_|_|            |\n'
			printf '|_____________________________________________________________________|\n'
			printf '|                                                                     |\n'
			printf '| Requirements: jffs partition and USB drive with entware installed   |\n'
			printf '|                                                                     |\n'
			printf '| The install script will:                                            |\n'
			printf '|   1. install the stubby entware package                             |\n'
			printf '|   2. override how the firmware manages DNS                          |\n'
			printf '|   3. disable the firmware DNSSEC setting                            |\n'
			printf '|   4. default to Cloudflare DNS 1.1.1.1. You can change to other     |\n'
			printf '|      supported DNS over TLS providers by modifying                  |\n'
			printf '|      /opt/etc/stubby/stubby.yml                                     |\n'
			printf '|                                                                     |\n'
			printf '| You can also use this script to uninstall Stubby to back out the    |\n'
			printf '| changes made during the installation. See the project repository at |\n'
			printf '| %bhttps://github.com/Xentrk/Stubby-Installer-Asuswrt-Merlin%b           |\n' "$COLOR_GREEN" "$COLOR_WHITE"
			printf '| for helpful tips.                                                   |\n'
			printf '|_____________________________________________________________________|\n'
			printf '\n'
			if pidof stubby >/dev/null 2>&1; then
				printf '%b1%b = Update Stubby Configuration\n' "${COLOR_GREEN}" "${COLOR_WHITE}"
			else
				printf '%b1%b = Begin Stubby Installation Process\n' "${COLOR_GREEN}" "${COLOR_WHITE}"
			fi
			printf '%b2%b = Remove Existing Stubby Installation\n' "${COLOR_GREEN}" "${COLOR_WHITE}"
			if [ "$localmd5" != "$remotemd5" ]; then
				printf '%b3%b = Update install_stubby.sh\n' "${COLOR_GREEN}" "${COLOR_WHITE}"
			fi
			printf '\n%be%b = Exit Script\n' "${COLOR_GREEN}" "${COLOR_WHITE}"
			printf '\n%bOption ==>%b ' "${COLOR_GREEN}" "${COLOR_WHITE}"
			read -r "menu1"
			case "$menu1" in
				1)
					install_stubby "$@"
					break
				;;
				2)
					validate_removal
					break
				;;
				3)
					update_installer
					break
				;;
				e)
					exit_message
					break
				;;
				*)
					printf '%bInvalid Option%b %s%b Please enter a valid option\n' "$COLOR_RED" "$COLOR_GREEN" "$menu1" "$COLOR_WHITE"
				;;
			esac
		done
}

validate_removal () {
		while true; do
			printf '\nIMPORTANT: %bThe router will need to reboot in order to complete the removal of Stubby%b\n' "${COLOR_RED}" "${COLOR_WHITE}"
			printf '%by%b = Are you sure you want to uninstall Stubby?\n' "${COLOR_GREEN}" "${COLOR_WHITE}"
			printf '%bn%b = Cancel\n' "${COLOR_GREEN}" "${COLOR_WHITE}"
			printf '%be%b = Exit Script\n' "${COLOR_GREEN}" "${COLOR_WHITE}"
			printf '\n%bOption ==>%b ' "${COLOR_GREEN}" "${COLOR_WHITE}"
			read -r "menu3"
			case "$menu3" in
				y)
					remove_existing_installation
					break
				;;
				n)
					welcome_message
					break
				;;
				e)
					exit_message
					break
				;;
				*)
					printf '%bInvalid Option%b %s%b Please enter a valid option\n' "$COLOR_RED" "$COLOR_GREEN" "$menu3" "$COLOR_WHITE"
				;;
			esac
		done
}

remove_existing_installation () {
		echo "Starting removal of Stubby"

		# Kill stubby process
		pidof stubby | while read -r "spid" && [ -n "$spid" ]; do
			kill "$spid"
		done


		# Remove the stubby package
		Chk_Entware stubby
		if [ "$READY" -eq "0" ]; then
			echo "Existing stubby package found. Removing Stubby"
			if opkg remove stubby; then echo "Stubby successfully removed"; else echo "Error occurred when removing Stubby"; fi
			if opkg remove getdns; then echo "GetDNS successfully removed"; else echo "Error occurred when removing GetDNS"; fi
		else
			echo "Unable to remove Stubby. Entware is not mounted"
		fi


		# Remove entries from /jffs/configs/dnsmasq.conf.add
		if [ -s "/jffs/configs/dnsmasq.conf.add" ]; then  # file exists
			for DNSMASQ_PARM in "no-resolv" "server=127.0.0.1#5453" "server=0::1#5453" "server=/pool.ntp.org/1.1.1.1" "proxy-dnssec"; do
				if grep -q "$DNSMASQ_PARM" "/jffs/configs/dnsmasq.conf.add"; then  # see if line exists
					sed -i "\\~$DNSMASQ_PARM~d" "/jffs/configs/dnsmasq.conf.add"
				fi
			done
		fi

		# Purge stubby directories
		for DIR in "/opt/var/cache/stubby" "/opt/etc/stubby"; do
			if [ -d "$DIR" ]; then
				if ! rm "$DIR"/* >/dev/null 2>&1; then
					printf '\nNo files found to remove in %b%s%b\n' "$COLOR_GREEN" "$DIR" "$COLOR_WHITE"
				fi
				if ! rmdir "$DIR" >/dev/null 2>&1; then
					printf '\nError trying to remove %b%s%b\n' "$COLOR_GREEN" "$DIR" "$COLOR_WHITE"
				else
					printf '\n%b%s%b folder and all files removed\n' "$COLOR_GREEN"  "$DIR" "$COLOR_WHITE"
				fi
			else
				printf '\n%b%s%b folder does not exist. No directory to remove\n' "$COLOR_GREEN" "$DIR" "$COLOR_WHITE"
			fi
		done

		# /opt/var/log/stubby log file
		if [ -f "/opt/var/log/stubby.log" ]; then  # file exists
			rm "/opt/var/log/stubby.log"
		fi

		# /opt/var/log message to user
		if [ -d "/opt/var/log" ]; then
			printf '\nDirectory %b/opt/var/log%b found. Skipping deletion of directory as it may be used by other applications\n' "$COLOR_GREEN" "$COLOR_WHITE"
			printf 'You can manually delete %b/opt/var/log%b if not used by other applications\n' "$COLOR_GREEN" "$COLOR_WHITE"
		fi

		# Remove /jffs/configs/resolv.dnsmasq
		if [ -f "/jffs/configs/resolv.dnsmasq" ]; then  # file exists
			rm "/jffs/configs/resolv.dnsmasq"
		fi

		# remove file /opt/etc/init.d/S61stubby
		if [ -d "/opt/etc/init.d" ]; then
			/opt/bin/find /opt/etc/init.d -type f -name S61stubby\* -delete
		fi

		# remove /jffs/scripts/openvpn-event
		if [ -s "/jffs/scripts/openvpn-event" ]; then  # file exists
			if grep -q "cp /jffs/configs/resolv.dnsmasq /tmp/resolv.dnsmasq" "/jffs/scripts/openvpn-event"; then  # see if line exists
				sed -i '\~resolv.dnsmasq~d' "/jffs/scripts/openvpn-event" >/dev/null 2>&1
				printf '\n%bresolv.dnsmasq%b line entry removed from %b/jffs/scripts/openvpn-event%b\n' "$COLOR_GREEN" "$COLOR_WHITE" "$COLOR_GREEN" "$COLOR_WHITE"
				printf 'Skipping deletion of %b/jffs/scripts/openvpn-event%b\n' "$COLOR_GREEN" "$COLOR_WHITE"
				printf 'You can manually delete %b/jffs/scripts/openvpn-event%b using the %brm%b command if no longer required\n' "$COLOR_GREEN" "$COLOR_WHITE" "$COLOR_GREEN" "$COLOR_WHITE"
			fi
		fi

		# Default DNS1 to Cloudflare 1.1.1.1
		DNS1="1.1.1.1"
		nvram set wan0_dns="$DNS1"
		nvram set wan_dns="$DNS1"
		nvram set wan_dns1_x="$DNS1"
		nvram set wan0_xdns="$DNS1"
		nvram set wan0_dns1_x="$DNS1"

		if [ "$(nvram get ipv6_service)" != "disabled" ]; then
			IPV6_DNS1="2606:4700:4700::1111"
			nvram set ipv6_dns1="$IPV6_DNS1"
			nvram set ipv61_dns1="$IPV6_DNS1"
		fi

		nvram commit

		# Remove /opt symlink
		rm -rf "/opt/bin/install_stubby" "/jffs/scripts/install_stubby.sh"

		# reboot router to complete uninstall of Stubby
		echo "Uninstall of Stubby completed. DNS has been set to Cloudflare 1.1.1.1"
		echo "The router will now reboot to finalize the removal of Stubby"
		echo "After the reboot, review the DNS settings on the WAN GUI and adjust if necessary"
		echo "Press Enter To Continue"
		read -r
		reboot
}

Chk_Entware () {
		# ARGS [wait attempts] [specific_entware_utility]
		READY="1"					# Assume Entware Utilities are NOT available
		ENTWARE_UTILITY=""			# Specific Entware utility to search for
		MAX_TRIES="30"

		if [ -n "$2" ] && [ "$2" -eq "$2" ] 2>/dev/null; then
			MAX_TRIES="$2"
		elif [ -z "$2" ] && [ "$1" -eq "$1" ] 2>/dev/null; then
			MAX_TRIES="$1"
		fi

		if [ -n "$1" ] && ! [ "$1" -eq "$1" ] 2>/dev/null; then
			ENTWARE_UTILITY="$1"
		fi

		# Wait up to (default) 30 seconds to see if Entware utilities available.....
		TRIES="0"

		while [ "$TRIES" -lt "$MAX_TRIES" ]; do
			if [ -f "/opt/bin/opkg" ]; then
				if [ -n "$ENTWARE_UTILITY" ]; then            # Specific Entware utility installed?
					if [ -n "$(opkg list-installed "$ENTWARE_UTILITY")" ]; then
						READY="0"                                 # Specific Entware utility found
					else
						# Xentrk revision needed to bypass false positive that stubby is installed if /opt/var/cache/stubby
						# and /opt/etc/stubby exists. When stubby is removed via the command line, the entware directory
						# is not deleted.

						# check for stubby folders with no files
						for DIR in /opt/var/cache/stubby /opt/etc/stubby; do
							if [ -d "$DIR" ]; then
								if ! is_dir_empty "$DIR"; then
									if ! rmdir "$DIR" >/dev/null 2>&1; then
										printf '\nError trying to remove %b%s%b\n' "$COLOR_GREEN" "$DIR" "$COLOR_WHITE"
									else
										printf '\norphaned %b%s%b folder removed\n' "$COLOR_GREEN"  "$DIR" "$COLOR_WHITE"
									fi
								fi
							fi
						done
						# Not all Entware utilities exists as a stand-alone package e.g. 'find' is in package 'findutils'
						if [ -d /opt ] && [ -n "$(find /opt/ -name "$ENTWARE_UTILITY")" ]; then
							READY="0"                               # Specific Entware utility found
						fi
					fi
				else
					READY="0"                                     # Entware utilities ready
				fi
				break
			fi
			sleep 1
			logger -st "($(basename "$0"))" "$$ Entware $ENTWARE_UTILITY not available - wait time $((MAX_TRIES - TRIES-1)) secs left"
			TRIES=$((TRIES + 1))
		done
		return "$READY"
}

is_dir_empty () {
		DIR="$1"
		cd "$DIR" || return 1
		set -- .[!.]* ; test -f "$1" && return 1
		set -- ..?* ; test -f "$1" && return 1
		set -- * ; test -f "$1" && return 1
		return 0
}

check_dnsmasq_parms () {
		if [ -s "/tmp/etc/dnsmasq.conf" ]; then  # dnsmasq.conf file exists
			for DNSMASQ_PARM in "no-resolv" "server=127.0.0.1#5453" "server=0::1#5453" "server=/pool.ntp.org/1.1.1.1"; do
				if grep -q "$DNSMASQ_PARM" "/tmp/etc/dnsmasq.conf"; then  # see if line exists
					printf 'Required dnsmasq parm %b%s%b found in /tmp/etc/dnsmasq.conf\n' "${COLOR_GREEN}" "$DNSMASQ_PARM" "${COLOR_WHITE}"
					continue #line found in dnsmasq.conf, no update required to /jffs/configs/dnsmasq.conf.add
				fi
				if [ -s "/jffs/configs/dnsmasq.conf.add" ]; then
					if grep -q "$DNSMASQ_PARM" "/jffs/configs/dnsmasq.conf.add"; then  # see if line exists
						printf '%b%s%b found in /jffs/configs/dnsmasq.conf.add\n' "${COLOR_GREEN}" "$DNSMASQ_PARM" "${COLOR_WHITE}"
					else
						printf 'Adding %b%s%b to /jffs/configs/dnsmasq.conf.add\n' "${COLOR_GREEN}" "$DNSMASQ_PARM" "${COLOR_WHITE}"
						printf '%s\n' "$DNSMASQ_PARM" >> /jffs/configs/dnsmasq.conf.add
					fi
				else
					printf 'Adding %b%s%b to /jffs/configs/dnsmasq.conf.add\n' "${COLOR_GREEN}" "$DNSMASQ_PARM" "${COLOR_WHITE}"
					printf '%s\n' "$DNSMASQ_PARM" > /jffs/configs/dnsmasq.conf.add
				fi
			done
		else
			echo "dnsmasq.conf file not found in /tmp/etc. dnsmasq appears to not be configured on your router. Check router configuration"
			exit 1
		fi
}

create_required_directories () {
		for DIR in "/opt/var/cache/stubby" "/opt/var/log" "/opt/etc/stubby"; do
			if [ ! -d "$DIR" ]; then
				if mkdir -p "$DIR" >/dev/null 2>&1; then
					printf "Created project directory %b%s%b\\n" "${COLOR_GREEN}" "${DIR}" "${COLOR_WHITE}"
				else
					printf "Error creating directory %b%s%b. Exiting $(basename "$0")\\n" "${COLOR_GREEN}" "${DIR}" "${COLOR_WHITE}"
					exit 1
				fi
			fi
		done
}

make_backup () {
		DIR="$1"
		FILE="$2"
		TIMESTAMP="$(date +%Y-%m-%d_%H-%M-%S)"
		BACKUP_FILE_NAME="${FILE}.${TIMESTAMP}"
		if [ -f "$DIR/$FILE" ]; then
			if ! mv "$DIR/$FILE" "$DIR/$BACKUP_FILE_NAME" >/dev/null 2>&1; then
				printf 'Error backing up existing %b%s%b to %b%s%b\n' "$COLOR_GREEN" "$FILE" "$COLOR_WHITE" "$COLOR_GREEN" "$BACKUP_FILE_NAME" "$COLOR_WHITE"
				printf 'Exiting %s\n' "$(basename "$0")"
				exit 1
			else
				printf 'Existing %b%s%b found\n' "$COLOR_GREEN" "$FILE" "$COLOR_WHITE"
				printf '%b%s%b backed up to %b%s%b\n' "$COLOR_GREEN" "$FILE" "$COLOR_WHITE" "$COLOR_GREEN" "$BACKUP_FILE_NAME" "$COLOR_WHITE"
			fi
		fi
}

download_file () {
		DIR="$1"
		FILE="$2"
		STATUS="$(curl --retry 3 -sL -w '%{http_code}' "$GITHUB_DIR/$FILE" -o "$DIR/$FILE")"
		if [ "$STATUS" -eq "200" ]; then
			printf '%b%s%b downloaded successfully\n' "$COLOR_GREEN" "$FILE" "$COLOR_WHITE"
		else
			printf '%b%s%b download failed with curl error %s\n' "$COLOR_GREEN" "$FILE" "$COLOR_WHITE" "$STATUS"
			printf 'Rerun %binstall_stubby.sh%b and select the %bRemove Existing Stubby Installation%b option\n' "$COLOR_GREEN" "$COLOR_WHITE" "$COLOR_GREEN" "$COLOR_WHITE"
			exit 1
		fi
}

stubby_yml_update () {
		make_backup /opt/etc/stubby stubby.yml
		download_file /opt/etc/stubby stubby.yml
		chmod 644 /opt/etc/stubby/stubby.yml >/dev/null 2>&1
		if [ "$(uname -m)" = "aarch64" ]; then
			{ printf '\n\n# Tweaks for statically linked binaries\n'
			echo "tls_min_version: GETDNS_TLS1_3"
			echo "tls_ciphersuites: \"TLS_AES_128_GCM_SHA256:TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256\""; } >> /opt/etc/stubby/stubby.yml
		fi
}


S61stubby_update () {
		if [ -d "/opt/etc/init.d" ]; then
			/opt/bin/find /opt/etc/init.d -type f -name S61stubby\* | while IFS= read -r "line"; do
				rm "$line"
			done
		fi
		download_file /opt/etc/init.d S61stubby
		chmod 755 /opt/etc/init.d/S61stubby >/dev/null 2>&1
}

check_openvpn_event() {
		SERVER="$1"
		COUNTER="0"
		for OPENVPN_CLIENT in 1 2 3 4 5; do
			if [ "$(nvram get vpn_client${OPENVPN_CLIENT}_state)" -eq "2" ]; then
				COUNTER=$((COUNTER + 1))
			fi
		done

		if [ "$COUNTER" -gt "0" ]; then
		# need /jffs/configs/resolv.dnsmasq override
			echo "server=${SERVER}" > /jffs/configs/resolv.dnsmasq
			if [ "$COUNTER" -gt "1" ]; then
				  WORD="Clients"
			elif [ "$COUNTER" -eq "1" ]; then
				  WORD="Client"
			fi

			# require override file if OpenVPN Clients are used
			echo "$COUNTER active OpenVPN $WORD found"
			if [ -s "/jffs/scripts/openvpn-event" ]; then  # file exists
				if ! grep -q "cp /jffs/configs/resolv.dnsmasq /tmp/resolv.dnsmasq" "/jffs/scripts/openvpn-event"; then
					echo "cp /jffs/configs/resolv.dnsmasq /tmp/resolv.dnsmasq" >> /jffs/scripts/openvpn-event
					printf 'Updated %b/jffs/scripts/openvpn-event%b\n' "$COLOR_GREEN" "$COLOR_WHITE"
				else
					printf 'Required entry already exists in %b/jffs/scripts/openvpn-event%b\n' "$COLOR_GREEN" "$COLOR_WHITE"
					printf 'Skipping update of %b/jffs/scripts/openvpn-event%b\n' "$COLOR_GREEN" "$COLOR_WHITE"
				fi
			else
				echo "#!/bin/sh" > /jffs/scripts/openvpn-event
				echo "cp /jffs/configs/resolv.dnsmasq /tmp/resolv.dnsmasq" >> /jffs/scripts/openvpn-event
				chmod 755 /jffs/scripts/openvpn-event
				printf 'Created %b/jffs/scripts/openvpn-event%b\n' "$COLOR_GREEN" "$COLOR_WHITE"
			fi
		else
			printf 'No active OpenVPN Clients found. Skipping creation of %b/jffs/scripts/openvpn-event%b\n' "$COLOR_GREEN" "$COLOR_WHITE"
			echo "If you decide to run an OpenVPN Client in the future, rerun the installer script"
			echo "to update /jffs/scripts/openvpn-event"
		fi
}

update_wan_and_resolv_settings () {
		# Update Connect to DNS Server Automatically
		nvram set wan_dnsenable_x="0"
		nvram set wan0_dnsenable_x="0"

		LAN_IP="$(nvram get lan_ipaddr)"
		DNS1="$LAN_IP"
		NAMESERVER="$LAN_IP"
		SERVER="$LAN_IP"
		RTR_IP="$(nvram get ipv6_rtr_addr)"

		# Set firmare nameserver and server entries
		echo "nameserver $NAMESERVER" > /tmp/resolv.conf
		echo "server=${SERVER}" > /tmp/resolv.dnsmasq

		# Set DNS1 based on user option
		nvram set wan0_dns="$DNS1"
		nvram set wan_dns="$DNS1"
		nvram set wan_dns1_x="$DNS1"
		nvram set wan0_xdns="$DNS1"
		nvram set wan0_dns1_x="$DNS1"

		# Set DNS2 to null
		nvram set wan_dns2_x=""
		nvram set wan0_dns2_x=""

		if [ "$(nvram get ipv6_service)" != "disabled" ]; then
			nvram set ipv6_dnsenable="0"
			nvram set ipv61_dnsenable="0"
			echo "server=${RTR_IP}" >> /tmp/resolv.dnsmasq
			nvram set ipv6_dns1="$RTR_IP"
			nvram set ipv6_dns2=""
			nvram set ipv6_dns3=""
			nvram set ipv61_dns1="$RTR_IP"
			nvram set ipv61_dns2=""
			nvram set ipv61_dns3=""
		fi

		# Choose DNSSEC setting
		nvram set dnssec_enable="0"
		DNSMASQ_PARM="proxy-dnssec"
		while true; do
			printf '\n\nWould you like to cache DNSSEC Authenticated Data? (proxy-dnssec)\n'
			echo "[1]  --> Yes"
			echo "[2]  --> No"
			echo
			printf "[1-2]: "
			read -r "menu2"
			echo
			case "$menu2" in
				1)
					if grep -q "$DNSMASQ_PARM" "/jffs/configs/dnsmasq.conf.add"; then
						printf '%b%s%b found in /jffs/configs/dnsmasq.conf.add\n' "${COLOR_GREEN}" "$DNSMASQ_PARM" "${COLOR_WHITE}"
					else
						printf 'Adding %b%s%b to /jffs/configs/dnsmasq.conf.add\n' "${COLOR_GREEN}" "$DNSMASQ_PARM" "${COLOR_WHITE}"
						printf '%s\n' "$DNSMASQ_PARM" >> /jffs/configs/dnsmasq.conf.add
					fi
					break
				;;
				2)
					if grep -q "$DNSMASQ_PARM" "/jffs/configs/dnsmasq.conf.add"; then
						sed -i "\\~$DNSMASQ_PARM~d" "/jffs/configs/dnsmasq.conf.add"
					fi
					break
				;;
				*)
					echo "[*] $menu2 Isn't An Option!"
				;;
			esac
		done

		# Commit nvram values
		nvram commit

		check_openvpn_event "$SERVER"
}

exit_message () {
		printf '\n   %bhttps://github.com/Xentrk/Stubby-Installer-Asuswrt-Merlin%b\n' "$COLOR_GREEN" "$COLOR_WHITE\\n"
		printf '                      Have a Grateful Day!\n\n'
		printf '           ____        _         _                           \n'
		printf '          |__  |      | |       | |                          \n'
		printf '    __  __  _| |_ _ _ | |_  ___ | | __    ____ ____  _ _ _   \n'
		printf '    \ \/ / |_  | %b %b \  __|/ _ \| |/ /   /  _//    \| %b %b \ \n' "\`" "\`" "\`" "\`"
		printf '     /  /  __| | | | |  |_ | __/|   <   (  (_ | [] || | | |  \n'
		printf '    /_/\_\|___ |_|_|_|\___|\___||_|\_\[] \___\\\____/|_|_|_| \n\n\n'
		exit 0
}

install_stubby () {
		if [ -d "/jffs/dnscrypt" ] || [ -f "/opt/sbin/dnscrypt-proxy" ]; then
			echo "Warning! DNSCrypt installation detected"
			printf 'Please remove this script to continue installing Stubby\n\n'
			exit 1
		fi
		echo
		if Chk_Entware; then
			if opkg update >/dev/null 2>&1; then
				echo "Entware package list successfully updated";
			else
				echo "An error occurred updating Entware packagelist"
				exit 1
			fi
		else
			echo "You must first install Entware before proceeding"
			printf 'Exiting %s\n' "$(basename "$0")"
			exit 1
		fi

		if [ "$(uname -m)" = "aarch64" ]; then
			download_file /tmp getdns-hnd-latest.ipk
			if opkg install /tmp/getdns-hnd-latest.ipk --force-downgrade; then
				echo "Patched getdns successfully installed"
			else
				echo "An error occurred installing patched Getdns"
				exit 1
			fi
			if opkg install stubby; then
				echo "Patched stubby successfully installed"
			else
				echo "An error occurred installing patched Stubby"
				exit 1
			fi
			rm /tmp/getdns-hnd-latest.ipk
		else
			if opkg install stubby getdns; then
				echo "Stubby successfully updated"
			else
				echo "An error occurred updating Stubby"
				exit 1
			fi
		fi

		if Chk_Entware haveged; then
			echo "Existing haveged package found"
			if opkg install haveged; then
				echo "Haveged successfully updated"
			else
				echo "An error occurred updating Haveged"
				exit 1
			fi
		else
			if opkg install haveged; then
				echo "Haveged successfully installed"
			else
				echo "An error occurred installing Haveged";
				exit 1
			fi
		fi
		/opt/etc/init.d/S02haveged restart

		check_dnsmasq_parms
		create_required_directories
		stubby_yml_update
		S61stubby_update
		update_wan_and_resolv_settings

		if [ -d "/opt/bin" ] && [ ! -L "/opt/bin/install_stubby" ]; then
			ln -s /jffs/scripts/install_stubby.sh /opt/bin/install_stubby
		fi

		service restart_dnsmasq >/dev/null 2>&1
		/opt/etc/init.d/S61stubby restart

		if pidof stubby >/dev/null 2>&1; then
			echo "Installation of Stubby completed"
		else
			echo "Warning! Unsuccesful installation of Stubby detected"
			printf 'Rerun %binstall_stubby.sh%b and select the %bRemove%b option to backout changes\n' "$COLOR_GREEN" "$COLOR_WHITE" "$COLOR_GREEN" "$COLOR_WHITE"
		fi

		exit_message
}

update_installer () {
	if [ "$localmd5" != "$remotemd5" ]; then
		download_file /jffs/scripts install_stubby.sh
		printf '\nUpdate Complete! %s\n' "$remotemd5"
	else
		printf '\ninstall_stubby.sh is already the latest version. %s\n' "$localmd5"
	fi

	exit_message
}

clear
welcome_message "$@"

logger -t "($(basename "$0"))" "$$ Ending Script Execution"
