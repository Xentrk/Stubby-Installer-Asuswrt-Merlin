# DO NOT USE TESTING IN PROGRESS!

# Stubby-Installer-Asuswrt-Merlin
Stubby DNS Privacy Daemon Install Script for Asuswrt-Merlin Firmware

## Description

[Stubby](https://dnsprivacy.org/wiki/display/DP/DNS+Privacy+Daemon+-+Stubby) is an application that acts as a local DNS Privacy stub resolver (using DNS-over-TLS). Stubby encrypts DNS queries sent from a client machine (desktop or laptop) to a DNS Privacy resolver increasing end user privacy.

## Requirements
1. An Asus router with  [Asuswrt-Merlin](http://asuswrt.lostrealm.ca/) firmware installed.
2. A USB drive with entware installed.  Entware can be installed using [amtm - the SNBForum Asuswrt-Merlin Terminal Menu](https://www.snbforums.com/threads/amtm-the-snbforum-asuswrt-merlin-terminal-menu.42415/)

The use of Stubby on Asuswrt-Merlin is experimental and not endorsed by the firmware developer. As an extra precaution, it is highly recommended to take a back-up of the jffs partition and the firmware configuration before proceeding with the installation. You can also use this script to uninstall Stubby and remove the changes made during the installation.   

The Stubby installer script **stubby_installer.sh** will
1. Install the entware packages **stubby** and **ca-certificates**
2. Override how the firmware manages DNS  
3. Default to Cloudflare DNS 1.1.1.1. You can change to other supported DNS over TLS providers by modifying **/opt/etc/stubby/stubby.yml**.
4. Provide the option to remove Stubby and the firmware DNS overrides.

## Installation
Copy and paste the command below into an SSH session.
```javascript
/usr/sbin/curl --retry 3 "https://raw.githubusercontent.com/Xentrk/Stubby-Installer-Asuswrt-Merlin/master/install_stubby.sh" -o /jffs/scripts/install_stubby.sh && chmod 755 /jffs/scripts/install_stubby.sh && sh /jffs/scripts/install_stubby.sh
```

## Validating that Stubby is Working
Run the following commands from an SSH session to verify that stubby is working properly:

**ps | grep stubby | grep -v grep**

    21283 admin    5560 S    stubby -g -v 5 -C /opt/etc/stubby/stubby.yml 2>/opt/var/log/stubby.log

**netstat -lnptu | grep stubby**

    tcp        0      0 127.0.0.1:5453          0.0.0.0:*               LISTEN      21283/stubby
    udp        0      0 127.0.0.1:5453          0.0.0.0:*                           21283/stubby

**drill github.com** (requires entware package drill)

    ;; ->>HEADER<<- opcode: QUERY, rcode: NOERROR, id: 41290
    ;; flags: qr rd ra ; QUERY: 1, ANSWER: 2, AUTHORITY: 0, ADDITIONAL: 0
    ;; QUESTION SECTION:
    ;; github.com.  IN      A

    ;; ANSWER SECTION:
    github.com.     42      IN      A       192.30.253.113
    github.com.     42      IN      A       192.30.253.112

    ;; AUTHORITY SECTION:

    ;; ADDITIONAL SECTION:

    ;; Query time: 82 msec
    ;; EDNS: version 0; flags: ; udp: 1452
    ;; SERVER: 127.0.0.1
    ;; WHEN: Wed Oct 10 10:23:23 2018
    ;; MSG SIZE  rcvd: 91

**nslookup github.com**

    Server:    127.0.0.1
    Address 1: 127.0.0.1 localhost.localdomain

    Name:      github.com
    Address 1: 192.30.253.113 lb-192-30-253-113-iad.github.com
    Address 2: 192.30.253.112 lb-192-30-253-112-iad.github.com

**stubby -l**

    [10:13:13.838111] STUBBY: Read config from file /opt/etc/stubby/stubby.yml
    [10:13:13.844362] STUBBY: DNSSEC Validation is OFF
    [10:13:13.844413] STUBBY: Transport list is:
    [10:13:13.844426] STUBBY:   - TLS
    [10:13:13.844439] STUBBY: Privacy Usage Profile is Strict (Authentication required)
    [10:13:13.844450] STUBBY: (NOTE a Strict Profile only applies when TLS is the ONLY transport!!)
    [10:13:13.844461] STUBBY: Starting DAEMON....
    [10:13:33.075865] STUBBY: 1.1.1.1                                  : Conn opened: TLS - Strict Profile
    [10:13:33.144900] STUBBY: 1.1.1.1                                  : Verify passed : TLS
    [10:13:35.163106] STUBBY: 1.1.1.1                                  : Conn closed: TLS - Resps=     1, Timeouts  =     0, Curr_auth =Success, Keepalive(ms)=  2000
    [10:13:35.163158] STUBBY: 1.1.1.1                                  : Upstream   : TLS - Resps=     1, Timeouts  =     0, Best_auth =Success
    [10:13:35.163173] STUBBY: 1.1.1.1                                  : Upstream   : TLS - Conns=     1, Conn_fails=     0, Conn_shuts=      0, Backoffs     =     0
Press **Ctrl-C** to return to the command prompt.

**echo | openssl s_client -connect '1.1.1.1:853'**

    CONNECTED(00000003)
    depth=2 C = US, O = DigiCert Inc, OU = www.digicert.com, CN = DigiCert Global Root CA
    verify return:1
    depth=1 C = US, O = DigiCert Inc, CN = DigiCert ECC Secure Server CA
    verify return:1
    depth=0 C = US, ST = CA, L = San Francisco, O = "Cloudflare, Inc.", CN = *.cloudflare-dns.com
    verify return:1
    ---
    Certificate chain
    0 s:/C=US/ST=CA/L=San Francisco/O=Cloudflare, Inc./CN=*.cloudflare-dns.com
    i:/C=US/O=DigiCert Inc/CN=DigiCert ECC Secure Server CA
    1 s:/C=US/O=DigiCert Inc/CN=DigiCert ECC Secure Server CA
    i:/C=US/O=DigiCert Inc/OU=www.digicert.com/CN=DigiCert Global Root CA
    ---
    Server certificate
    -----BEGIN CERTIFICATE-----
    MIID9DCCA3qgAwIBAgIQBWzetBRl/ycHFsBukRYuGTAKBggqhkjOPQQDAjBMMQsw
    CQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMSYwJAYDVQQDEx1EaWdp
    <snip>

Check the last few lines of the output from the **echo | openssl s_client -connect '1.1.1.1:853'** command.  If you see the message

    Verify return code: 20 (unable to get local issuer certificate)

in the last few lines, enter the following command:

    echo | openssl s_client -verify on -CApath /opt/etc/ssl/certs -connect  1.1.1.1:853

Use the [Cloudflare Help Page](https://1.1.1.1/help) to validate you are connected to 1.1.1.1 and **DNS over TLS** is working.  If working properly, the page will display a **Yes** as seen in the example below:

    Connected to 1.1.1.1         Yes
    Using DNS over HTTPS (DoH)   No
    Using DNS over TLS (DoT)     Yes

## Validation with Quad9
Quad9 blocks the website http://isitblocked.org. If Quad9 is working properly, an **nslookup isitblocked.org** will fail:

    Server:    127.0.0.1
    Address 1: 127.0.0.1 localhost.localdomain

    nslookup: can't resolve 'isitblocked.org'

## Starting, Stopping and Killing Stubby
To **(start|stop|restart|check|kill|reconfigure)** stubby, type the command below where **option** is one of the options listed in the parenthesis.

    /opt/etc/init.d/S61stubby option

## DNS over TLS with OpenVPN
To configure an OpenVPN Client to use Stubby DNS, set **Accept DNS Configuration = Disabled** on the **VPN->VPN Client** page.  Then, select the **Apply** button to save the setting.

## DNSSEC
The **install_stubby.sh** script turns off the DNSSEC setting on the firmware to avoid conflicts with DNSSEC built into Stubby.

## DNSSEC, DNS Spoof, DNS Leak and WebRTC Leak Test Web Sites
1. DNSSEC Test

  * https://rootcanary.org/test.html
  * http://dnssec.vs.uni-due.de/
  * http://en.conn.internet.nl/connection/

2. DNS Nameserver Spoofability Test
  * https://www.grc.com/dns/dns.htm (scroll down and click on "Initiate Standard DNS Spoofability Test")
  *	https://www.dns-oarc.net/oarc/services/dnsentropy

3. DNS Leak Test

  * https://www.dnsleaktest.com/ (use Extended test)
  *	https://ipleak.net/
  * https://www.perfect-privacy.com/dns-leaktest/

4. WebRTC Leak Test

  * https://browserleaks.com/webrtc
  * https://ip8.com/webrtc-test
  * https://ipx.ac/run
  * https://www.perfect-privacy.com/check-ip/
  * https://www.doileak.com/

## Collaborators

* [Martineau](https://www.snbforums.com/members/martineau.13215/) on snbforums.com provided the **Chk_Entware** function.

* [John9527](https://www.snbforums.com/members/john9527.27638/) is the developer of the [Asuswrt-Merlin Fork](https://github.com/john9527/asuswrt-merlin). **John9527** implemented Stubby in August 2018 and provided the **stubby.yml** configuration generated by the firmware **Asuswrt-Merlin-Fork**. The **stubby.yml** provided by **John9527** was used as a benchmark for this project.  My goal is to standardize the configurations used in the [Asuswrt-Merlin Fork](https://github.com/john9527/asuswrt-merlin) when possible.     

* Thank you to snbforum members [skeal](https://www.snbforums.com/members/skeal.47960/) and [M@rco](https://www.snbforums.com/members/m-rco.56284/) who volunteered their time performing testing and providing feedback.

## Support

Support for the project is available on snbforums.com (Link Coming Soon)
