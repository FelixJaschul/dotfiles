#!/bin/bash
WIFI_IF=$(nmcli device status | awk '$2=="wifi" {print $1; exit}')

get_sound() {
    LINE=$(wpctl status | awk '/Sinks:/{flag=1; next} /Sources:/{flag=0} flag && /\*/' | head -1)
    if [ -z "$LINE" ]; then echo "N/A"; return; fi
    if echo "$LINE" | grep -q "MUTED"; then echo "XX%"; return; fi
    VOL=$(echo "$LINE" | sed -n 's/.*vol: \([0-9.]*\).*/\1/p')
    #PERCENT=$(awk -v v="$VOL" 'BEGIN {val=int(v*100); printf "%d", (val > 100 ? 100 : val)}')
    PERCENT=$(awk -v v="$VOL" 'BEGIN {printf("%d", v*100)}')
    echo "${PERCENT}%"
}

get_cpu() {
    read -r _ c1 < /proc/stat
    sleep 0.2
    read -r _ c2 < /proc/stat
    awk -v a="$c1" -v b="$c2" 'BEGIN {
        split(a,x); split(b,y)
        idle1=x[4]; total1=0; for(i in x) total1+=x[i]
        idle2=y[4]; total2=0; for(i in y) total2+=y[i]
        printf "%d", 100*(1-(idle2-idle1)/(total2-total1))
    }'
}

print_status() {
    SOUND=$(get_sound)
    WIFI=$(nmcli -t -f GENERAL.CONNECTION dev show "$WIFI_IF" 2>/dev/null | awk -F: '{gsub(/^ +| +$/,"",$2); print $2}')
    [ -z "$WIFI" ] && WIFI="No Wi-Fi"
    BAT=$(cat /sys/class/power_supply/macsmc-battery/capacity)
    STATUS=$(cat /sys/class/power_supply/macsmc-battery/status)
    CPU=$(get_cpu)
    RAM=$(free -h | awk '/^Mem:/ {print $3 "/" $2}')
    DATE=$(date "+%Y-%m-%d %H:%M")
    echo "SOUND: $SOUND | WIFI: $WIFI | RAM: $RAM | CPU: $CPU% | BATTERY: $BAT% $STATUS | $DATE"
}

trap 'kill $SLEEP_PID 2>/dev/null' RTMIN+1

while true; do
    print_status
    sleep 5 &
    SLEEP_PID=$!
    wait $SLEEP_PID
done
