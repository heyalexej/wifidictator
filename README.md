# WiFi Dictator
**Keeps Leeches At Bay**

I was at a coworking space the other day and had massive troubles with slow internet. After looking over a couple of shoulders I realized that half of the crowd was watching Miley Cyrus videos on YouTube in full HD while the other half was seemingly downloading the very same videos. I got so pissed off that I went into rage mode and started to deauthenticate all of the people (except me of course) by hand. I wrote a dirty script to do this every minute. Unfair, I know. Then I thought I have to write something that would only kick the leeches who stream video or download torrents. I found a [script][11] that is doing exactly that. I modified it to automatically detect interfaces, MAC address etc..

The script puts your interface into monitor mode and inspects the network traffic with [Airodump-ng][2]. The results are written into a CSV file. Then it parses the CSV and grabs the MAC addresses of clients who are being stupid. The "stupidity" threshold is based on packet count over a defined period (Default is 200 pakets in 5 seconds, you might need to play with this a bit). We use some AWK fun to get this info, then launch [Aireplay-ng][7] to [inject][8] our deauth frames, and we'll also go ahead and spoof the MAC of the base station, because connected clients tend to ignore deauth frames not coming from there.

_If you're having [driver][5] problems, I feel bad for you son. I got 99 chipsets [but Broadcom ain't one][6]._


Requirements
------------

* [Aircrack-ng][1]
* [iwgetid][12]


Usage
-----
Clone the repo and change into directory:
```bash
$ git clone git@github.com:heyalexej/wifidictator.git
$ cd wifidictator
```

Run it like so:
```bash
$ sudo ./wifidictator.sh
```


This script is largely based on [work][11] from [@ip2k][10] which he published under [CC BY-NC-SA 3.0][9].

[1]: http://www.aircrack-ng.org
[2]: http://www.aircrack-ng.org/doku.php?id=airodump-ng
[3]: http://www.aircrack-ng.org/doku.php?id=airmon-ng&s[]=monitor&s[]=mode
[4]: http://madwifi-project.org/
[5]: http://www.aircrack-ng.org/doku.php?id=compatibility_drivers&s[]=injection
[6]: http://www.aircrack-ng.org/doku.php?id=injection_test&s[]=injection
[7]: http://www.aircrack-ng.org/doku.php?id=aireplay-ng
[8]: http://www.aircrack-ng.org/doku.php?id=injection_test&s[]=injection
[9]: http://creativecommons.org/licenses/by-nc-sa/3.0/
[10]: https://github.com/ip2k
[11]: https://github.com/ip2k/WiFi-Abuse-Autokiller
[12]: http://linux.die.net/man/8/iwgetid