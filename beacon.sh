#!/bin/bash
#
# $Id$

[[ "$1" == '-h' ]] && echo "$0 [path to template dir (/etc/nagios/contact_protocols)]" && exit 1
# debug mode
DEBUG="echo"
# contact protocol application paths
PROWL="$DEBUG prowl.pl"
NMA="$DEBUG nma.pl"
MAILBIN="$DEBUG /usr/bin/mail"
TEMPLATE_DIR=${1:-'/etc/nagios/contact_protocols'}

# testing
if [ -e /tmp/service-notification -a -n "$DEBUG" ]; then
  for x in $(< /tmp/service-notification); do
    eval export $x &> /dev/null
  done
fi


function determine_contact() {
  # nagios supports 6 contactaddresses
  for n in $(seq 0 5); do
    local proto
    local apikey
    local notify_num
    local contactaddr
    eval ca1="NAGIOS_CONTACTADDRESS${n}"
    eval contactaddr=\$$ca1
    proto=$( echo $contactaddr | awk -F: '{ print $1 }' )
    apikey=$( echo $contactaddr | awk -F: '{ print $2 }' )
    notify_num=$( echo $contactaddr | awk -F: '{ print $3 }' )
    notify_num=${notify_num:=0}

    if [ "$NAGIOS_NOTIFICATIONNUMBER" -gt "$notify_num" ]; then
      send $proto $apikey
    fi
  done
}

function send() {
  local proto=$1
  local addr=${2:-$proto}
  local subject=${subject:='missing subject'}
  local message=${message:='missing body'}
  local title=${title:='missing title'}
  local priority=${priority:=1}

  [ "$proto" == "$addr" ] && unset proto
  [ -n "$url" ] && url_option="-url $url"
  if [ -e ${TEMPLATE_DIR}/${proto}.${NAGIOS_NOTIFICATIONTYPE}.template.sh ]; then
    [ -n "$DEBUG" ] && echo "Loading template ${TEMPLATE_DIR}/${proto}.${NAGIOS_NOTIFICATIONTYPE}.template.sh"
    . ${TEMPLATE_DIR}/${proto}.${NAGIOS_NOTIFICATIONTYPE}.template.sh
  elif [ -e ${TEMPLATE_DIR}/${proto}.template.sh ]; then
    [ -n "$DEBUG" ] && echo "Loading template ${TEMPLATE_DIR}/${proto}.template.sh"
    . ${TEMPLATE_DIR}/${proto}.template.sh
  else
    [ -n "$DEBUG" ] && echo "Loading template ${TEMPLATE_DIR}/template.sh"
    . ${TEMPLATE_DIR}/template.sh || echo "no suitable template found" >> /dev/stderr
  fi

  ## add contact protocols here ##
  case $proto in
    prowl)
      eval $PROWL \
        -apikey=\"${addr}\" \
        -event=\"${subject}\" \
        -notification=\"${message}\" \
        -priority="${priority}" \
        -application=\"${title}\" \
        $url_option
      ;;
    nma)
      eval $NMA \
        -apikey=\"${addr}\" \
        -event=\"${subject}\" \
        -notification=\"${message}\" \
        -priority="${priority}" \
        -application=\"${title}\"
      ;;
    sms)
      eval $SMS
      ;;
    email)
      eval $MAILBIN
      ;;
    '')
      ;;
    *)
      echo "unsupported command: $proto"
      ;;
  esac
}

# run our main logic
determine_contact
