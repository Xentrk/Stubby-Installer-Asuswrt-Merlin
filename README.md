# Stubby-Installer-Asuswrt-Merlin

Stubby DNS Privacy Daemon Install Script for [Asuswrt-Merlin](https://asuswrt.lostrealm.ca/) Firmware

## Description

[Stubby](https://dnsprivacy.org/wiki/display/DP/DNS+Privacy+Daemon+-+Stubby) is an application that acts as a local DNS Privacy stub resolver using DNS-over-TLS. Stubby encrypts DNS queries sent from a client machine to a DNS Privacy resolver increasing end user privacy.

The use of Stubby on [Asuswrt-Merlin](https://asuswrt.lostrealm.ca/) is not endorsed by the firmware developer. You can also use this script to uninstall Stubby and remove the changes made during the installation.   

The Stubby installer script **install_stubby.sh** will
1. Install the entware packages **stubby**.
2. Create **/opt/var/cache/stubby** and **/opt/var/log** folders if they do not exist.
3. Download the Stubby entware start up script **S61stubby** to **/opt/etc/init.d**.
4. Download the Stubby configuration file **stubby.yml** to **/opt/etc/stubby**.
5. Override how the firmware manages DNS

*   Add the entry **no-resolv** to **/jffs/configs/dnsmasq.conf.add** if it does not exist in **/tmp/dnsmasq.conf**.
*   Add the entries **server=127.0.0.1#5453** and **server=0::1#5453** to **/jffs/configs/dnsmasq.conf.add**.  This instructs dnsmasq to forward DNS requests to Stubby.
*   Set WAN DNS1 to the Router's IP Address and set the WAN DNS2 entry to null.
*   Update **/tmp/resolv.conf** and **/tmp/resolv.dnsmasq** to use the Router's IP address.
*   If one or more active OpenVPN Clients are found, create the file **/jffs/configs/resolv.dnsmasq** and add an entry in **/jffs/scripts/openvpn-event** to copy **/jffs/configs/resolv.dnsmasq** to **/tmp/resolv.dnsmasq**.  This is required to prevent OpenVPN up/down events from adding the internal VPN DNS server IP addresses 10.9.0.1 and 10.8.0.1 to **/tmp/resolv.dnsmasq**.

6.  Default to Cloudflare DNS 1.1.1.1 using DNS over TLS. You can change to other supported DNS over TLS providers by modifying **/opt/etc/stubby/stubby.yml**.
7.  Provide the option to remove Stubby and the firmware DNS overrides created during the installation. The uninstall option will set the WAN DNS1 to use Cloudflare 1.1.1.1 without DNS over TLS. A reboot is required to finalize the removal of Stubby. You can modify the DNS settings after the reboot has completed.

## Requirements

1.  An Asus router with  [Asuswrt-Merlin](http://asuswrt.lostrealm.ca/) firmware installed.
2.  A USB drive with [entware](https://github.com/RMerl/asuswrt-merlin/wiki/Entware) installed.  Entware can be installed using [amtm - the SNBForum Asuswrt-Merlin Terminal Menu](https://www.snbforums.com/threads/amtm-the-snbforum-asuswrt-merlin-terminal-menu.42415/)

## Supported Models

All Asus models that are [supported by Asuswrt-Merlin](https://asuswrt.lostrealm.ca/about). I have received confirmation that it works on the following models:

*   RT-AC66U_B1
*   RT-AC68U
*   RT-AC87U
*   RT-AC88U
*   RT-AC3100
*   RT-AC3200
*   RT-AC5300
*   RT-AC86U
*   RT-AX88U
*   GT-AC5300

## Installation

Copy and paste the command below into an SSH session.

```Shell
/usr/sbin/curl --retry 3 "https://raw.githubusercontent.com/Xentrk/Stubby-Installer-Asuswrt-Merlin/master/install_stubby.sh" -o "/jffs/scripts/install_stubby.sh" && chmod 755 /jffs/scripts/install_stubby.sh && sh /jffs/scripts/install_stubby.sh
```
You may also install Stubby using [amtm - the SNBForum Asuswrt-Merlin Terminal Menu](https://www.snbforums.com/threads/amtm-the-snbforum-asuswrt-merlin-terminal-menu.42415/)

## Stubby Configuration

See the [Stubby Configuration Guide](https://dnsprivacy.org/wiki/display/DP/Configuring+Stubby) for a description of the configuration file options. For information on how I derived at the settings used in this project, see my blog post [DNS over TLS with DNSMASQ and Stubby on Asuswrt-Merlin](https://x3mtek.com/dns-over-tls-with-dnsmasq-and-stubby-on-asuswrt-merlin/).  

## Validating that Stubby is Working

Run the following commands from an SSH session to verify that stubby is working properly:

### ps | grep stubby | grep -v grep

```
21283 admin    5560 S    stubby -g -v 5 -C /opt/etc/stubby/stubby.yml 2>/opt/var/log/stubby.log
```

### /opt/etc/init.d/S61stubby check

```
Checking stubby...              alive.
```

### netstat -lnptu | grep stubby
```
    tcp        0      0 127.0.0.1:5453          0.0.0.0:*               LISTEN      21283/stubby
    udp        0      0 127.0.0.1:5453          0.0.0.0:*                           21283/stubby
```

### netstat -lnpt | grep -E '^Active|^Proto|/stubby'

```
    Active Internet connections (only servers)
    Proto Recv-Q Send-Q Local Address           Foreign Address         State       PID/Program name
    tcp        0      0 127.0.0.1:5453          0.0.0.0:*               LISTEN      24290/stubby
```

### drill github.com (requires entware package drill)

```
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
```

### nslookup github.com

```
    Server:    127.0.0.1
    Address 1: 127.0.0.1 localhost.localdomain

    Name:      github.com
    Address 1: 192.30.253.113 lb-192-30-253-113-iad.github.com
    Address 2: 192.30.253.112 lb-192-30-253-112-iad.github.com
```

### getdns_query -s @127.0.0.1 github.com

```
    <snip>
    "status": GETDNS_RESPSTATUS_GOOD
    }
```

### stubby -l

```Shell
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
```

### echo | openssl s_client -verify on -CAfile /rom/etc/ssl/certs/ca-certificates.crt -connect 1.1.1.1:853

```Shell
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
```

### Use the [Cloudflare Help Page](https://1.1.1.1/help) to validate you are connected to 1.1.1.1 and **DNS over TLS** is working.  If working properly, the page will display a **Yes** as seen in the example below

```Shell
    Connected to 1.1.1.1         Yes
    Using DNS over HTTPS (DoH)   No
    Using DNS over TLS (DoT)     Yes
```

Similariliy, the [Cloudflare Browsing Experience Security Check](https://www.cloudflare.com/ssl/encrypted-sni/) page tests whether your DNS queries and answers are encrypted, whether your DNS resolver uses DNSSEC, which version of TLS is used to connect to the page, and whether your browser supports encrypted Server Name Indication (SNI).

## Validation with Quad9

Quad9 blocks the website [http://isitblocked.org](http://isitblocked.org). If Quad9 is working properly, an **nslookup isitblocked.org** will fail:

```Shell
    Server:    127.0.0.1
    Address 1: 127.0.0.1 localhost.localdomain

    nslookup: can't resolve 'isitblocked.org'
```

## Known Issues

1.  The [Cloudflare Help Page](https://1.1.1.1/help) test page will not work when the secondary IPv6 **2606:4700:4700::1001** is specified in **/opt/etc/stubby/stubby.yml**.
2.  Stubby logging is currently simplistic or non-existent and simply writes to stdout. The Stubby team is working on making this better!

## Starting, Stopping and Killing Stubby

To **(start|stop|restart|check|kill|reconfigure)** stubby, type the command below where **option** is one of the options listed in the parenthesis.

```Shell
    /opt/etc/init.d/S61stubby option
```

## DNS over TLS with OpenVPN

To configure an OpenVPN Client to use Stubby DNS, set **Accept DNS Configuration = Disabled** on the **VPN->VPN Client** page. Select the **Apply** button to save the setting.

## Blocking Client DNS requests

A client device with DNS configured will override the DNS configured on the router. To override client DNS settings and force all LAN clients to use Stubby, enter the following commands in an SSH session.

```Shell
    iptables -t nat -A PREROUTING -i br0 -p udp --dport 53 -j DNAT --to "$(nvram get lan_ipaddr)"
    iptables -t nat -A PREROUTING -i br0 -p tcp --dport 53 -j DNAT --to "$(nvram get lan_ipaddr)"
```

Add the commands to **/jffs/scripts/firewall-start** in order for the rules to be applied upon a restart.

## DNSSEC

The **install_stubby.sh** script turns off the DNSSEC setting on the firmware to avoid conflicts with DNSSEC built into Stubby. Stubby uses **getdns** to manage DNSSEC. **getdns** uses a form of built-in trust-anchor management modeled on [RFC7958](https://tools.ietf.org/html/rfc7958), named [Zero configuration DNSSEC](https://getdnsapi.net/releases/getdns-1-2-0/).  If you turn on the firmware DNSSEC, the [Cloudflare Help Page](https://1.1.1.1/help) test page will not work. Early in my testing, I had root anchor files in the **appdata_dir** directory **/opt/var/cache/stubby**. Later in my testing, no root anchor files appeared in the **appdata_dir** directory. I created an [issue](https://github.com/getdnsapi/stubby/issues/136) with the Stubby support team. However, I did not receive a reply from my updates.  Since the DNSSEC test sites worked, I closed the issue.

## DNS-over-TLS, DNSSEC, DNS Spoof, DNS Leak and WebRTC Leak Test Web Sites

1.  DNS-over-TLS Test

*   [Cloudflare Help Page](https://1.1.1.1/help)
*   [Cloudflare Browsing Experience Security Check](https://www.cloudflare.com/ssl/encrypted-sni/)

2.  DNSSEC Test

*   [https://rootcanary.org/test.html](https://rootcanary.org/test.html)
*   [http://dnssec.vs.uni-due.de/](https://rootcanary.org/test.html)
*   [http://en.conn.internet.nl/connection/](http://en.conn.internet.nl/connection/)
*   [http://0skar.cz/dns/en/](http://0skar.cz/dns/en/)

3.  DNS Nameserver Spoofability Test

*   [https://www.grc.com/dns/dns.htm](https://www.grc.com/dns/dns.htm) (scroll down and click on "Initiate Standard DNS Spoofability Test")
*   [https://www.dns-oarc.net/oarc/services/dnsentropy](https://www.dns-oarc.net/oarc/services/dnsentropy)

4.  DNS Leak Test

*   [https://www.dnsleaktest.com/](https://www.dnsleaktest.com/) (use Extended test)
*   [https://ipleak.net/](https://ipleak.net/)
*   [https://www.perfect-privacy.com/dns-leaktest/](https://www.perfect-privacy.com/dns-leaktest/)

5.  WebRTC Leak Test

*   [https://browserleaks.com/webrtc](https://browserleaks.com/webrtc)
*   [https://ip8.com/webrtc-test](https://ip8.com/webrtc-test)
*   [https://ipx.ac/run](https://ipx.ac/run)
*   [https://www.perfect-privacy.com/check-ip/](https://www.perfect-privacy.com/check-ip/)
*   [https://www.doileak.com/](https://www.doileak.com/)

## Collaborators

*   [Martineau](https://www.snbforums.com/members/martineau.13215/) on snbforums.com provided the **Chk_Entware** function.

*   [John9527](https://www.snbforums.com/members/john9527.27638/) is the developer of the [Asuswrt-Merlin Fork](https://github.com/john9527/asuswrt-merlin). *John9527* implemented Stubby in August 2018 and provided the **stubby.yml** configuration generated by the firmware **Asuswrt-Merlin-Fork**. The **stubby.yml** provided by *John9527* was used as a benchmark for this project.  My goal is to standardize the configurations used in the [Asuswrt-Merlin Fork](https://github.com/john9527/asuswrt-merlin) when possible.     

*   Thank you to [snbforums.com](https://www.snbforums.com/) members [Jack Yaz](https://www.snbforums.com/members/jack-yaz.53009/), [bbunge](https://www.snbforums.com/members/bbunge.30783/),  [skeal](https://www.snbforums.com/members/skeal.47960/) and [M@rco](https://www.snbforums.com/members/m-rco.56284/) who volunteered their time performing testing and providing feedback.

*   [Jack Yaz](https://www.snbforums.com/members/jack-yaz.53009/) forked the original installer to provide support for RT-AC86U routers.  
*   [Adamm](https://www.snbforums.com/members/adamm.19554/) also forked the original installer script and added support for the RT-AX88U and GT-AC5300 HND routers. Adamm performed code improvements and implemented the performance improvements listed below.

*   Odkrys compiled Stubby for HND routers RT-AC86U, RT-AX88U, GT-AC5300 and provided performance improvement suggestions: TLS 1.3 / Cipher List / haveged

All updates made by [Jack Yaz](https://www.snbforums.com/members/jack-yaz.53009/) and [Adamm](https://www.snbforums.com/members/adamm.19554/) are now incorporated into the original installer script.

## Support

Support for the project is available on [snbforums.com](https://www.snbforums.com/threads/stubby-installer-asuswrt-merlin.49469/)
