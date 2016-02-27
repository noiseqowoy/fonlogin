#!/bin/sh
IF="eth1"
WGET="/opt/bin/wget"
PW="123456"
USERNAME="nosuser@domain.com"
USER_AGENT="Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/48.0.2564.109 Safari/537.36"
TARGET_SSID="FON_ZON_FREE_INTERNET"
# Test for SSID and IP address
refresh () {
        SSID_NOW=$(wl ssid | sed -e 's/Current SSID: //g' | sed -e 's/"//g')
        IP_NOW=$(ifconfig $IF | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}')
}
refresh
while [ [ $SSID_NOW != $TARGET_SSID ] || [ $IP_NOW == '' ] ]; do
        refresh
        gpio enable 2; gpio enable 3
        sleep 1
        gpio disable 2; gpio disable 3
        sleep 1
done
echo "Client associated with $TARGET_SSID, got IP, trying connection"

# Test Host
ping -c 1 sapo.pt > /dev/null 2>&1
if  [ $? -ne 0 ];
then
        echo "Logging on the system"
        $WGET  -qO- --output-document=captive.html --no-check-certificate --save-cookies=cookie --user-agent="$USER_AGENT" --keep-session-cookies http://www.sapo.pt
        export URL=$(cat captive.html | grep '<LoginURL>' | sed -e 's/<[^>]*>//g' | sed -e 's/ //g' | sed -e 's/amp;//g')
        #echo $URL
        $WGET  -q --no-check-certificate --load-cookies=cookie --keep-session-cookies --user-agent="$USER_AGENT" --post-data="Password=$PW&UserName=NOS/$USERNAME&_rememberMe=on&UserFake=$USERNAME" $URL
        rm -f captive.html
        sleep 4
        ping -c 1 sapo.pt > /dev/null 2>&1
        if [ $? = '0' ];
        then
                echo "Connection successeful"
                ntpclient pt.pool.ntp.org > /dev/null 2>&1
                exit 1
        else
                echo "Failure";
                exit 2
        fi
else
        echo "Already connected"
        exit 0
fi
