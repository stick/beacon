#!/bin/sh
#
# $Id$

usage() {
    echo "Usage:"
    echo "$0 [OPTIONS]"
    echo "Uploads a tree to a channel"
    echo
    echo "  OPTIONS:"
    echo "    --help        display usage and exit"
    echo "    -apikey          apikey/address"
    echo "    -event           event/subject"
    echo "    -notification    notification/message"
    echo "    -priority        priority"
    echo "    -application     external application/not used"
    echo
    exit $1
}

while true; do
    case "$1" in
        --help)
            usage 0
            ;;
        -apikey)
            case "$2" in
                "") echo "No parameter specified for -apikey"; break;;
                *)  APIKEY=$2; shift 2;;
            esac;;
        -event)
            case "$2" in
                "") echo "No parameter specified for -event"; break;;
                *)  EVENT=$2; shift 2;;
            esac;;
        -notification)
            case "$2" in
                "") echo "No parameter specified for -notification"; break;;
                *)  NOTIFICATION=$2; shift 2;;
            esac;;
        -priority)
            case "$2" in
                "") echo "No parameter specified for -priority"; break;;
                *)  PRIORITY=$2; shift 2;;
            esac;;
        -application)
            case "$2" in
                "") echo "No parameter specified for -application"; break;;
                *)  APPLICATION=$2; shift 2;;
            esac;;
        "") break;;
        *) echo "Unknown keywords $*"; usage 1;;
    esac
done

declare -a priorities
priorities[-2]="very low"
priorities[-1]="moderate"
priorities[0]="normal"
priorities[1]="high"
priorities[2]="emergency"


# ideally this would be something like sendpage/qpage
if [ -n "$PRIORITY" ]; then
  printf "%b" "Priority: $priorities[$PRIORITY] - $EVENT\n\n$NOTIFICATION" | qpage $APIKEY
else
  printf "%b" "$EVENT\n\n$NOTIFICATION" | qpage $APIKEY
fi

