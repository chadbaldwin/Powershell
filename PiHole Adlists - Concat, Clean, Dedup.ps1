# Generate sample file
'https://adaway.org/hosts.txt
https://bitbucket.org/ethanr/dns-blacklists/raw/8575c9f96e5b4a1308f2f12394abd86d0927a4a0/bad_lists/Mandiant_APT1_Report_Appendix_D.txt
https://gitlab.com/quidsup/notrack-blocklists/raw/master/notrack-blocklist.txt
https://gitlab.com/quidsup/notrack-blocklists/raw/master/notrack-malware.txt
https://hostfiles.frogeye.fr/firstparty-trackers-hosts.txt
https://mirror.cedia.org.ec/malwaredomains/immortal_domains.txt
https://mirror1.malwaredomains.com/files/justdomains
https://osint.digitalside.it/Threat-Intel/lists/latestdomains.txt
https://pgl.yoyo.org/adservers/serverlist.php?hostformat=hosts&showintro=0&mimetype=plaintext
https://phishing.army/download/phishing_army_blocklist_extended.txt
https://raw.githubusercontent.com/anudeepND/blacklist/master/adservers.txt
https://raw.githubusercontent.com/bigdargon/hostsVN/master/hosts
https://raw.githubusercontent.com/crazy-max/WindowsSpyBlocker/master/data/hosts/spy.txt
https://raw.githubusercontent.com/DandelionSprout/adfilt/master/Alternate%20versions%20Anti-Malware%20List/AntiMalwareHosts.txt
https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.2o7Net/hosts
https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.Risk/hosts
https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.Spam/hosts
https://raw.githubusercontent.com/FadeMind/hosts.extras/master/UncheckyAds/hosts
https://raw.githubusercontent.com/PolishFiltersTeam/KADhosts/master/KADhosts_without_controversies.txt
https://raw.githubusercontent.com/Spam404/lists/master/main-blacklist.txt
https://s3.amazonaws.com/lists.disconnect.me/simple_ad.txt
https://s3.amazonaws.com/lists.disconnect.me/simple_malvertising.txt
https://urlhaus.abuse.ch/downloads/hostfile/
https://v.firebog.net/hosts/AdguardDNS.txt
https://v.firebog.net/hosts/Admiral.txt
https://v.firebog.net/hosts/Easylist.txt
https://v.firebog.net/hosts/Easyprivacy.txt
https://v.firebog.net/hosts/Prigent-Ads.txt
https://v.firebog.net/hosts/Prigent-Crypto.txt
https://v.firebog.net/hosts/Prigent-Malware.txt
https://v.firebog.net/hosts/Shalla-mal.txt
https://v.firebog.net/hosts/static/w3kbl.txt
https://www.malwaredomainlist.com/hostslist/hosts.txt
https://zerodot1.gitlab.io/CoinBlockerLists/hosts_browser' | Set-Content -NoNewLine .\AdLists.txt

# Download files using URLs from AdList
$lists = gc .\AdLists.txt
rm .\URLBatch.txt
$lists | % { write "Downloading file: $_"; irm $_ -TimeoutSec 5 | Out-File -Append .\URLBatch.txt }
write 'Load URLs';
$blockURLs = gc .\URLBatch.txt

write 'Clean urls';
$blockURLs = ForEach ($URL in $blockURLs) {
	if ($URL -match '^[\s\t]{0,}#.*$') { continue }; #Ignore comment only lines
	if ($URL -match '^[\s\t]{0,}$') { continue }; #Ignore blank lines
	$URL = $URL -Replace '^(0\.0\.0\.0|127\.0\.0\.1|::1|::)[\s\t]{0,}(.*)$','$2' #Remove redirects to localhost/0.0.0.0
	$URL = $URL -Replace '^(.*)[\s\t]{0,}#.*$','$1' #Remove comments at end of lines
	if ($URL -eq 'localhost') { continue };
	if ($URL -match '[\s\t]') { $URL = $URL -Split '[\s\t]{1,}' } #Split lines with multiple URLs
	$URL = $URL.Trim([char]0x200e); #LTR Character
	$URL.Trim();
}

write 'Dedup URLs';
$blockURLs = $blockURLs | ? { $_ -match '^.*\..*$' } | sort -Unique

write 'Write back to file';
$blockURLs | Out-File .\Blocklist.txt
