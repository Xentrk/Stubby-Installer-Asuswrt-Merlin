# Stubby-Installer-Asuswrt-Merlin
Stubby DNS Privacy Daemon Install Script for Asuswrt-Merlin Firmware

## Description

[Stubby](https://dnsprivacy.org/wiki/display/DP/DNS+Privacy+Daemon+-+Stubby) is an application that acts as a local DNS Privacy stub resolver (using DNS-over-TLS). Stubby encrypts DNS queries sent from a client machine (desktop or laptop) to a DNS Privacy resolver increasing end user privacy.

## Requirements
1. An Asus router with  [Asuswrt-Merlin](http://asuswrt.lostrealm.ca/) firmware installed.
2. A USB drive with entware installed.  Entware can be installed using [amtm - the SNBForum Asuswrt-Merlin Terminal Menu](https://www.snbforums.com/threads/amtm-the-snbforum-asuswrt-merlin-terminal-menu.42415/)

The use of Stubby on Asuswrt-Merlin is experimental and not endorsed by the firmware developer. As an extra precaution, it is highly recommended to take a back-up of the jffs partition and the firmware configuration before proceeding with the installation. You can also use this script to uninstall Stubby and remove the changes made during the installation.   

The Stubby installer script will
1. Install the entware packages **stubby** and **ca-certificates** on
2. Override how the firmware manages DNS  
3. Default to Cloudfare DNS 1.1.1.1. You can change to other supported DNS over TLS providers by modifying /opt/var/stubby/stubby.yml and the DNS Settings on the WAN Menu.

## Collaborators

Martineau on snbforums.com provided the **Chk_Entware** function.

## Support

Support for the project is available on snbforums.com
