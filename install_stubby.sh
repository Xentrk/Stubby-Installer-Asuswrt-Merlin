#!/bin/sh
####################################################################################################
# Script: install_stubby.sh
# Version 1.0.0
# Author: Xentrk
# Date: 28-September-2018
#
# Description:
#  Install the stubby DNS over TLS resolver and the ca-certificates packages from entware on Asuswrt-Merlin firmware.
#
# Acknowledgement:
#  Chk_Entware function provided by @Martineau at snbforums.com
#
####################################################################################################
logger -t "($(basename "$0"))" $$ Starting Script Execution

# Uncomment the line below for debugging
# set -x

Set_Color_Parms () {
    COLOR_RED='\033[0;31m'
    COLOR_WHITE='\033[0m'
    COLOR_GREEN='\e[0;32m'
}

welcome_message () {
    printf '\n'
    printf '#############################################################################################################\n'
    printf '##                                                                                                         ##\n'
    printf '##  Welcome to the %bStubby-Installer-Asuswrt-Merlin%b installation script                                     ##\n' "$COLOR_GREEN" "$COLOR_WHITE"
    printf '##  Version %s by Xentrk                                                                                ##\n' "$VERSION"
    printf '##                                                                                                         ##\n'
    printf '##         ____        _         _                                                                         ##\n'
    printf '##        |__  |      | |       | |                                                                        ##\n'
    printf '##  __  __  _| |_ _ _ | |_  ___ | | __    ____ ____  _ _ _                                                 ##\n'
    printf '##  \ \/ / |_  | %b %b \  __|/ _ \| |/ /   /  _//    \| %b %b \                                                ##\n' "\`" "\`" "\`" "\`"
    printf '##   /  /  __| | | | |  |_ | __/|   <   (  (_ | [] || | | |                                                ##\n'
    printf '##  /_/\_\|___ |_|_|_|\___|\___||_|\_\[] \___\\\____/|_|_|_|                                                ##\n'
    printf '##                                                                                                         ##\n'
    printf '#############################################################################################################\n'
    printf '##                                                                                                         ##\n'
    printf '## Stubby Wiki: https://dnsprivacy.org/wiki/display/DP/DNS+Privacy+Daemon+-+Stubby                         ##\n'
    printf '## Requirements: jffs partition and USB drive with entware installed                                       ##\n'
    printf '##                                                                                                         ##\n'
    printf '## The use of Stubby on Asuswrt-Merlin is experimental. The install script will:                           ##\n'
    printf '##   1. Install the stubby and ca-certificates entware packages                                            ##\n'
    printf '##   2. Override how the firmware manages DNS                                                              ##\n'
    printf '##   3. Default to Cloudfare DNS 1.1.1.1. You can change to other supported DNS over TLS providers by      ##\n'
    printf '##      modifying /opt/var/stubby/stubby.yml and the DNS Settings on the WAN Menu.                         ##\n'
    printf '##                                                                                                         ##\n'
    printf '## You can also use this script to uninstall Stubby to back out the changes made during the installation.  ##\n'
    printf '## As an extra precaution, it is highly recommended to take a back-up of the jffs partition, the firmware  ##\n'
    printf '## configuration and USB before proceeding with the installation. See the project repository at            ##\n'
    printf '## https://github.com/Xentrk/Stubby-Installer-Asuswrt-Merlin tips for helpful tips                         ##\n'
    printf '#############################################################################################################\n'
    printf '\n'
    printf '%b1%b = Begin Installation Process\n' "${COLOR_GREEN}" "${COLOR_WHITE}"
    printf '%b2%b = Remove Existing Installation\n' "${COLOR_GREEN}" "${COLOR_WHITE}"
    printf '%be%b = Exit Script\n' "${COLOR_GREEN}" "${COLOR_WHITE}"
    printf '\n'
    printf '%bOption ==>%b ' "${COLOR_GREEN}" "${COLOR_WHITE}"
    read -r f
        case $f in
	          1) 	install_stubby ;;
	          2)	validate_removal ;;
            e)  exit_message ;;
	          *)	printf '%bInvalid Option%b %s%b Please enter a valid option\n' "$COLOR_RED" "$COLOR_GREEN" "$f" "$COLOR_WHITE";
                welcome_message ;;
        esac
}

validate_removal () {
    printf '\n'
    printf '%by%b = Are you sure you want to unsintall stubby?\n' "${COLOR_GREEN}" "${COLOR_WHITE}"
    printf '%bn%b = Cancel\n' "${COLOR_GREEN}" "${COLOR_WHITE}"
    printf '%be%b = Exit Script\n' "${COLOR_GREEN}" "${COLOR_WHITE}"
    printf '\n'
    printf '%bOption ==>%b ' "${COLOR_GREEN}" "${COLOR_WHITE}"
    read -r f
        case $f in
	          y) 	remove_existing_installation ;;
	          n)	welcome_message ;;
            e)  exit_message ;;
	          *)	printf '%bInvalid Option%b %s%b Please enter a valid option\n' "$COLOR_RED" "$COLOR_GREEN" "$f" "$COLOR_WHITE";
                validate_removal ;;
        esac
}

Chk_Entware () {
    # ARGS [wait attempts] [specific_entware_utility]

    READY=1                   # Assume Entware Utilities are NOT available
    ENTWARE="opkg"
    ENTWARE_UTILITY=                # Specific Entware utility to search for
    MAX_TRIES=30

    if [ ! -z "$2" ] && [ ! -z "$(echo "$2" | grep -E '^[0-9]+$')" ];then
        MAX_TRIES=$2
    fi

    if [ ! -z "$1" ] && [ -z "$(echo "$1" | grep -E '^[0-9]+$')" ];then
        ENTWARE_UTILITY=$1
    else
        if [ -z "$2" ] && [ ! -z "$(echo "$1" | grep -E '^[0-9]+$')" ];then
            MAX_TRIES=$1
        fi
    fi

   # Wait up to (default) 30 seconds to see if Entware utilities available.....
   TRIES=0

   while [ "$TRIES" -lt "$MAX_TRIES" ];do
      if [ ! -z "$(which $ENTWARE)" ] && [ "$($ENTWARE -v | grep -o "version")" = "version" ];then
         if [ ! -z "$ENTWARE_UTILITY" ];then            # Specific Entware utility installed?
            if [ ! -z "$("$ENTWARE" list-installed "$ENTWARE_UTILITY")" ];then
                READY=0                                 # Specific Entware utility found
            else
                # Not all Entware utilities exists as a stand-alone package e.g. 'find' is in package 'findutils'
                if [ -d /opt ] && [ ! -z "$(find /opt/ -name "$ENTWARE_UTILITY")" ];then
                  READY=0                               # Specific Entware utility found
                fi
            fi
         else
            READY=0                                     # Entware utilities ready
         fi
         break
      fi
      sleep 1
      logger -st "($(basename "$0"))" $$ "Entware" "$ENTWARE_UTILITY" "not available - wait time" $((MAX_TRIES - TRIES-1))" secs left"
      TRIES=$((TRIES + 1))
   done

   return $READY
}

remove_existing_installation () {
    printf 'Starting removal of Stubby. Removal process will not remove ca-certificates since the package is often used by other programs.\n'

    # Kill stubby process
    # Kill stubby process
    $(pidof stubby) 1>/dev/null && $(kill pidof stubby) && printf 'Active Stubby process killed\n' || printf 'Found no active Stubby process found to kill\n'


    # Remove the stubby package
    Chk_Entware stubby
    if [ "$READY" -eq "0" ]; then
        printf "existing stubby package found\n"
        opkg remove stubby
    fi


    # Remove entries from /jffs/configs/dnsmasq.conf.add
    if [ -s /jffs/configs/dnsmasq.conf.add ]; then  # file exists
        if [ "$(grep -c 'server=127.0.0.1#5453' "/jffs/configs/dnsmasq.conf.add")" != "0" ]; then  # see if line exists
            sed -i '/server=127.0.0.1#5453/d' "/jffs/configs/dnsmasq.conf.add" > /dev/null 2>&1
        fi
        if [ "$(grep -c 'server=0::1#5453' "/jffs/configs/dnsmasq.conf.add")" != "0" ]; then  # see if line exists
            sed -i '/server=0::1#5453/d' "/jffs/configs/dnsmasq.conf.add" > /dev/null 2>&1
        fi
    fi

    # Purge stubby directories
    for DIR in /opt/var/cache/stubby /opt/etc/stubby
        do
            if [ -d "$DIR" ]; then
                if ! rm "$DIR"/* > /dev/null 2>&1; then
                printf '\n'
                printf 'No files found to remove in %b%s%b\n' "$COLOR_GREEN" "$DIR" "$COLOR_WHITE"
                fi
                if ! rmdir "$DIR" > /dev/null 2>&1; then
                    printf '\n'
                    printf 'Error trying to remove %b%s%b\n' "$COLOR_GREEN" "$DIR" "$COLOR_WHITE"
                else
                    printf '\n'
                    printf '%b%s%b folder and all files removed\n' "$COLOR_GREEN"  "$DIR" "$COLOR_WHITE"
                fi
            else
                printf '\n'
                printf '%b%s%b folder does not exist. No directory to remove.\n' "$COLOR_GREEN" "$DIR" "$COLOR_WHITE"
            fi
        done

    # /opt/var/log/stubby log file
    if [ -s /opt/var/log/stubby.log ]; then  # file exists
        rm /opt/var/log/stubby.log
    fi

    # /opt/var/log message to user
    if [ -d "/opt/var/log" ]; then
        printf '\n'
        printf 'Directory %b/opt/var/log%b found. Skipping deletion of directory as it may be used by other applications.\n' "$COLOR_GREEN" "$COLOR_WHITE"
        printf 'You can manually delete %b/opt/var/log%b if not used by other applications.\n' "$COLOR_GREEN" "$COLOR_WHITE"
    fi

    # Remove /jffs/configs/resolv.dnsmasq
    if [ -s /jffs/configs/resolv.dnsmasq ]; then  # file exists
        rm /jffs/configs/resolv.dnsmasq
    fi

    # remove file /opt/etc/init.d/S61stubby
    if [ -s /opt/etc/init.d/S61stubby ]; then  # file exists
        rm //opt/etc/init.d/S61stubby
    fi

    # remove /jffs/scripts/openvpn-event
    if [ -s /jffs/scripts/openvpn-event ]; then  # file exists
        if [ "$(grep -c "cp /jffs/configs/resolv.dnsmasq /tmp/resolv.dnsmasq" "/jffs/scripts/openvpn-event")" != "0" ]; then  # see if line exists
            sed -i '/resolv.dnsmasq/d' "/jffs/scripts/openvpn-event" > /dev/null 2>&1
            printf '\n'
            printf 'One line entry removed from %b/jffs/scripts/openvpn-event%b\n' "$COLOR_GREEN" "$COLOR_WHITE"
            printf 'Skipping deletion of %b/jffs/scripts/openvpn-event%b as it may be used by other applications.\n' "$COLOR_GREEN" "$COLOR_WHITE"
            printf 'You can manually delete %b/jffs/scripts/openvpn-event%b using the %brm%b command if not used by other applications.\n' "$COLOR_GREEN" "$COLOR_WHITE" "$COLOR_GREEN" "$COLOR_WHITE"
        fi
    fi

    # remove /jffs/scripts/dnsmasq.postconf
    if [ -s /jffs/scripts/dnsmasq.postconf ]; then  # file exists
    if [ "$(grep -c "cp /jffs/configs/resolv.dnsmasq /tmp/resolv.dnsmasq" "/jffs/scripts/dnsmasq.postconf")" != "0" ]; then  # see if line exists
            sed -i '/resolv.dnsmasq/d' "/jffs/scripts/dnsmasq.postconf" > /dev/null 2>&1
            printf '\n'
            printf 'One line entry removed from %b/jffs/scripts/dnsmasq.postconf%b\n' "$COLOR_GREEN" "$COLOR_WHITE"
            printf 'Skipping deletion of %b/jffs/scripts/dnsmasq.postconf%b as it may be used by other applications.\n' "$COLOR_GREEN" "$COLOR_WHITE"
            printf 'Manually remove %b/jffs/scripts/openvpn-event%b using the %brm%b command if the file is no longer required\n' "$COLOR_GREEN" "$COLOR_WHITE" "$COLOR_GREEN" "$COLOR_WHITE"
        fi
    fi

    # restart dnsmasq to reflect changes
    service restart_dnsmasq > /dev/null 2>&1

    printf 'Uninstall of Stubby completed.\n'
    printf 'Please review the DNS settings on the WAN GUI and adjust if necessary.\n'
}

exit_message () {
    printf '\n'
    printf '\n'
    printf 'Have a %bGrateful Day%b!\n' "$COLOR_GREEN" "$COLOR_WHITE"
    printf '\n'
    printf '           ____        _         _                           \n'
    printf '          |__  |      | |       | |                          \n'
    printf '    __  __  _| |_ _ _ | |_  ___ | | __    ____ ____  _ _ _   \n'
    printf '    \ \/ / |_  | %b %b \  __|/ _ \| |/ /   /  _//    \| %b %b \ \n' "\`" "\`" "\`" "\`"
    printf '     /  /  __| | | | |  |_ | __/|   <   (  (_ | [] || | | |  \n'
    printf '    /_/\_\|___ |_|_|_|\___|\___||_|\_\[] \___\\\____/|_|_|_| \n'
    printf '\n'
    printf '\n'
    exit 0
}

install_stubby () {

Chk_Entware () {
    # ARGS [wait attempts] [specific_entware_utility]

    READY=1                   # Assume Entware Utilities are NOT available
    ENTWARE="opkg"
    ENTWARE_UTILITY=                # Specific Entware utility to search for
    MAX_TRIES=30

    if [ ! -z "$2" ] && [ ! -z "$(echo "$2" | grep -E '^[0-9]+$')" ];then
        MAX_TRIES=$2
    fi

    if [ ! -z "$1" ] && [ -z "$(echo "$1" | grep -E '^[0-9]+$')" ];then
        ENTWARE_UTILITY=$1
    else
        if [ -z "$2" ] && [ ! -z "$(echo "$1" | grep -E '^[0-9]+$')" ];then
            MAX_TRIES=$1
        fi
    fi

   # Wait up to (default) 30 seconds to see if Entware utilities available.....
   TRIES=0

   while [ "$TRIES" -lt "$MAX_TRIES" ];do
      if [ ! -z "$(which $ENTWARE)" ] && [ "$($ENTWARE -v | grep -o "version")" = "version" ];then
         if [ ! -z "$ENTWARE_UTILITY" ];then            # Specific Entware utility installed?
            if [ ! -z "$("$ENTWARE" list-installed "$ENTWARE_UTILITY")" ];then
                READY=0                                 # Specific Entware utility found
            else
                # Xentrk revision needed to bypass false postive that stubby is installed if /opt/var/cache/stubby
                # and /opt/etc/stubby exists. When stubby is removed via the command line, the entware directory
                # is not deleted.

                # check for stubby folders with no files
                for DIR in /opt/var/cache/stubby /opt/etc/stubby
                    do
                        if [ -d "$DIR" ]; then
                            is_dir_empty $DIR
                            if [ "$?" -eq "0" ]; then
                                if ! rmdir "$DIR" > /dev/null 2>&1; then
                                    printf '\n'
                                    printf 'Error trying to remove %b%s%b\n' "$COLOR_GREEN" "$DIR" "$COLOR_WHITE"
                                else
                                    printf '\n'
                                    printf 'orphaned %b%s%b folder removed\n' "$COLOR_GREEN"  "$DIR" "$COLOR_WHITE"
                                fi
                            fi
                        fi
                    done

                # Not all Entware utilities exists as a stand-alone package e.g. 'find' is in package 'findutils'
                if [ -d /opt ] && [ ! -z "$(find /opt/ -name "$ENTWARE_UTILITY")" ];then
                  READY=0                               # Specific Entware utility found
                fi
            fi
         else
            READY=0                                     # Entware utilities ready
         fi
         break
      fi
      sleep 1
      logger -st "($(basename "$0"))" $$ "Entware" "$ENTWARE_UTILITY" "not available - wait time" $((MAX_TRIES - TRIES-1))" secs left"
      TRIES=$((TRIES + 1))
   done

   return $READY
}

is_dir_empty () {
    cd "$1"
    set -- .[!.]* ; test -f "$1" && return 1
    set -- ..?* ; test -f "$1" && return 1
    set -- * ; test -f "$1" && return 1
    return 0
}

check_dnsmasq_parms () {
    if [ -s /tmp/etc/dnsmasq.conf ]; then  # dnsmasq.conf file exists
        for DNSMASQ_PARM in "no-resolv" "server=127.0.0.1#5453" "server=0::1#5453"
            do
               if [ "$(grep -c "$DNSMASQ_PARM" "/tmp/etc/dnsmasq.conf")" != "0" ]; then  # see if line exists
                    printf '%s found in /tmp/etc/dnsmasq.conf. No need to add to /jffs/cofigs/dnsmasq.conf.add"\n' "$DNSMASQ_PARM"
                    continue #line found in dnsmasq.conf, no update required to /jffs/configs/dnsmasq.conf.add
               fi
               if [ -s /jffs/configs/dnsmasq.conf.add ]; then
                    if [ "$(grep -c "$DNSMASQ_PARM" "/jffs/configs/dnsmasq.conf.add")" != "0" ]; then  # see if line exists
                        printf '%s found in /jffs/configs/dnsmasq.conf.add\n' "$DNSMASQ_PARM"
                    else
                        printf 'Adding %s to /jffs/configs/dnsmasq.conf.add\n' "$DNSMASQ_PARM"
                        printf '%s\n' "$DNSMASQ_PARM" >> /jffs/configs/dnsmasq.conf.add
                    fi
                else
                    printf 'Adding %s to /jffs/configs/dnsmasq.conf.add\n' "$DNSMASQ_PARM"
                    printf '%s\n' "$DNSMASQ_PARM" > /jffs/configs/dnsmasq.conf.add
                fi
            done
    else
       printf "dnsmasq.conf file not found in /tmp/etc. dnsmasq appears to not be configured on your router. Check router configuration.\n"
       exit 1
    fi
}

create_required_directories () {
    for DIR in "/opt/var/cache/stubby" "/opt/var/log"
        do
            if [ ! -d "$DIR" ]; then
                mkdir "$DIR" > /dev/null 2>&1 && printf "Created project directory %b%s%b\n" "${COLOR_GREEN}" "${DIR}" "${COLOR_WHITE}" || printf "Error creating directory %b%s%b. Exiting $(basename "$0")\n" "${COLOR_GREEN}" "${DIR}" "${COLOR_WHITE}" || exit 1
            fi
        done
}

check_resolv_dnsmasq_override () {
    if [ -s /jffs/configs/resolv.dnsmasq ]; then  # file exists
        for SERVER_PARM in "server=127.0.0.1"
            do
               if [ "$(grep -c "$SERVER_PARM" "/jffs/configs/resolv.dnsmasq")" = "0" ]; then  # see if line exists
                   printf '%s\n' "$SERVER_PARM" > /jffs/configs/resolv.dnsmasq
               else
                   printf "/jffs/configs/resolv.dnsmasq override file already exists. No update required.\n"
               fi
            done
    else
       printf '%s\n' "$SERVER_PARM" > /jffs/configs/resolv.dnsmasq
    fi
}

make_backup () {
    DIR=$1
    FILE=$2
    TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
    BACKUP_FILE_NAME=${FILE}.${TIMESTAMP}

    if ! mv "$DIR/$FILE" "$DIR/$BACKUP_FILE_NAME" > /dev/null 2>&1; then
        printf 'Error backing up existing %b%s%b to %b%s%b\n' "$COLOR_GREEN" "$FILE" "$COLOR_WHITE" "$COLOR_GREEN" "$BACKUP_FILE_NAME" "$COLOR_WHITE"
        printf "Exiting %s)\n" "$(basename "$0")"
        exit 1
    else
        printf '%b%s%b backed up to %b%s%b\n' "$COLOR_GREEN" "$FILE" "$COLOR_WHITE" "$COLOR_GREEN" "$BACKUP_FILE_NAME" "$COLOR_WHITE"
    fi
}

download_file () {
    DIR=$1
    FILE=$2
    GIT_REPO="Stubby-Installer-Asuswrt-Merlin"
    GITHUB_DIR="https://raw.githubusercontent.com/Xentrk/$GIT_REPO/master"

    /usr/sbin/curl --retry 3 "$GITHUB_DIR/$FILE" -o "$DIR/$FILE"
}

stubby_yml_update () {
    if [ -s "/opt/etc/stubby/stubby.yml" ]; then
        make_backup /opt/etc/stubby stubby.yml
    fi
    download_file /opt/etc/stubby stubby.yml
    chmod 644 /opt/etc/stubby/stubby.yml > /dev/null 2>&1
}

S61stubby_update () {
    if [ -s "/opt/etc/init.d/S61stubby" ]; then
        make_backup /opt/etc/init.d S61stubby
    fi
    download_file /opt/etc/init.d S61stubby
    chmod 755 /opt/etc/init.d/S61stubby > /dev/null 2>&1
}

check_dnsmasq_postconf () {
    if [ -s /jffs/scripts/dnsmasq.postconf ]; then  # file exists
        if [ "$(grep -c "cp /jffs/configs/resolv.dnsmasq /tmp/resolv.dnsmasq" "/jffs/scripts/dnsmasq.postconf")" = "0" ]; then  # see if line exists
            printf '%s\n' "cp /jffs/configs/resolv.dnsmasq /tmp/resolv.dnsmasq" >> /jffs/scripts/dnsmasq.postconf
        fi
    else
        printf '%s\n' "#!/bin/sh" > /jffs/scripts/dnsmasq.postconf
        printf '%s\n' "cp /jffs/configs/resolv.dnsmasq /tmp/resolv.dnsmasq" >> /jffs/scripts/dnsmasq.postconf
        chmod 755 /jffs/scripts/dnsmasq.postconf
    fi
    cp /jffs/configs/resolv.dnsmasq /tmp/resolv.dnsmasq
}

check_openvpn_event() {
    COUNTER=0
    for OPENVPN_CLIENT in 1 2 3 4 5
        do
            if [ "$(nvram get vpn_client${OPENVPN_CLIENT}_state)" -eq "2" ]; then
                COUNTER=$((COUNTER + 1))
            fi
        done

    if [ "$COUNTER" -gt "0" ]; then
        if [ "$COUNTER" -gt "1" ]; then
              WORD=Clients
        elif [ "$COUNTER" -eq "1" ]; then
              WORD=Client
        fi

        printf '%s\n' "$COUNTER active OpenVPN $WORD found"
        if [ -s /jffs/scripts/openvpn-event ]; then  # file exists
            if [ "$(grep -c "cp /jffs/configs/resolv.dnsmasq /tmp/resolv.dnsmasq" "/jffs/scripts/openvpn-event")" = "0" ]; then  # see if line exists
                printf '%s\n' "cp /jffs/configs/resolv.dnsmasq /tmp/resolv.dnsmasq" >> /jffs/scripts/openvpn-event
                printf '%s\n' "/jffs/scripts/openvpn-event"
            else
                printf '%s\n' "Required entry already exists in /jffs/scripts/openvpn-event. Skipping update of /jffs/scripts/openvpn-event"
            fi
        else
            printf '%s\n' "#!/bin/sh" > /jffs/scripts/openvpn-event
            printf '%s\n' "cp /jffs/configs/resolv.dnsmasq /tmp/resolv.dnsmasq" >> /jffs/scripts/openvpn-event
            chmod 755 /jffs/scripts/openvpn-event > /dev/null 2>&1
            printf '%s\n' "Created /jffs/scripts/openvpn-event"
        fi
    else
        printf '%s\n' "No active OpenVPN Clients found. Skipping creation of /jffs/scripts/openvpn-event"
        printf '%s\n' "If you decide to run an OpenVPN Client in the future, rerun the installer script"
        printf '%s\n' "to update /jffs/scripts/openvpn-event."
    fi
}

update_wan_dns_settings () {
# Update Connect to DNS Server Automatically

    nvram set wan_dnsenable_x="0"
    nvram set wan0_dnsenable_x="0"

# Set DNS1 to use 1.1.1.1

    nvram set wan0_dns=1.1.1.1
    nvram set wan_dns=1.1.1.1
    nvram set wan_dns1_x=1.1.1.1
    nvram set wan0_xdns=1.1.1.1
    nvram set wan0_dns1_x=1.1.1.1

# Set DNS2 to null

  nvram set wan_dns2_x=""
  nvram set wan0_dns2_x=""

  nvram commit
}

###################### Main ################
Set_Color_Parms

Chk_Entware
    if [ "$READY" -eq "0" ]; then
        opkg update && printf "entware successfully updated\n" || printf "An error occurred updating entware\n" || exit 1
    else
        printf "You must first install Entware before proceeding.\n"
        printf "Exiting %s\n" "$(basename "$0")"
        exit 1
    fi

Chk_Entware stubby
    if [ "$READY" -eq "0" ]; then
        printf "existing stubby package found\n"
        # Kill stubby process
        $(pidof stubby) 1>/dev/null && $(kill pidof stubby) && printf 'Active Stubby process killed\n' || printf 'Found no active Stubby process found to kill\n'
        opkg update stubby && printf "stubby successfully updated\n" || printf "An error occurred updating stubby\n" || exit 1
    else
        opkg install stubby && printf "stubby successfully installed\n" || printf "An error occurred installing stubby\n" || exit 1
    fi

Chk_Entware ca-certificates
    if [ "$READY" -eq "0" ]; then
        printf "existing ca-certificates package found\n"
        opkg update ca-certifacates && printf "ca-certificates successfully updated\n" || printf "An error occurred updating ca-certificates\n" || exit 1
    else
        opkg install ca-certifacates && printf "ca-certificates successfully installed\n" || printf "An error occurred installing ca-certificates\n" || exit 1
    fi

check_dnsmasq_parms
create_required_directories
check_resolv_dnsmasq_override
stubby_yml_update
S61stubby_update
check_dnsmasq_postconf
check_openvpn_event
update_wan_dns_settings

service restart_dnsmasq
/opt/etc/init.d/S61stubby restart
}

clear
Set_Color_Parms
welcome_message

logger -t "($(basename "$0"))" $$ Ending Script Execution
