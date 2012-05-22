#!/bin/bash
#
# notification logic script for nagios
# 
# Copyright (C) 2012 Chris MacLeod
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# debug mode set prior to execution -- this shortcircutes execution and displays lots of info
DEBUG=${DEBUG:+'1'}

# contact protocol application paths
PROWL="/usr/local/sbin/prowl.pl"
NMA="nma.pl"
MAILBIN="/usr/bin/mail"
TEMPLATE_DIR=${1:-'/etc/nagios/contact_protocols'} # location of templates

# temlate searches
# there are two scopes, outer is iterated through
# inner is concatonated-shifted through
# make sure any macro vars used here are escaped
OUTER_SEARCH=( \$protocol ) # protocol is an internal var which the contect protocol 
INNER_SEARCH=( \$NAGIOS_NOTIFICATIONTYPE \$NAGIOS_CONTACTNAME )



### -- TAKE CAUTION CHANGING ANYTHING BELOW THIS LINE -- ###
[[ "$1" == '-h' ]] && echo "$0 [path to template dir (/etc/nagios/contact_protocols)]" && exit 1

if [ -n "$DEBUG" ]; then
  echo "Alert time: $NAGIOS_LONGDATETIME"
  env |grep NAGIOS_ > /tmp/macros
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

    if [ -n "$DEBUG" ]; then
      echo "Checking $ca1: $contactaddr"
    fi
    if [ "$NAGIOS_NOTIFICATIONNUMBER" -gt "$notify_num" ]; then
      send $proto $apikey
    fi
  done
}

function attempt_load() {
  local t_attempt=$1
  [[ -n "$DEBUG" ]] && echo "searching for $t_attempt"
  if [ -e "$t_attempt" ]; then
    [[ -n "$DEBUG" ]] && echo "Loading $t_attempt"
    . "$t_attempt" && return 0
  else
    return 1
  fi
}

function load_template() {
  local protocol=$1
  local template
  for o in ${OUTER_SEARCH[@]}; do
    eval s1=$o
    # make a copy of our array 
    declare -a scratch
    scratch=( ${INNER_SEARCH[*]} )
    for i in ${scratch[@]}; do
      local last_index=$(( ${#scratch[*]} - 1 ))
      OLDIFS=$IFS
      IFS="."
      eval full_t="${scratch[*]}"
      IFS=$OLDIFS
      template="${TEMPLATE_DIR}/${s1}.${full_t}.template.rc"
      unset scratch[${last_index}]
      attempt_load $template && return 0
    done
    attempt_load "${TEMPLATE_DIR}/${s1}.template.rc" && return 0
  done
  attempt_load "${TEMPLATE_DIR}/default.template.rc" || \
  echo "No default template found ($protocol $NAGIOS_CONTACTADDRESS)"
}


function send() {
  local proto=$1
  local addr=${2:-$proto}
  local subject=${subject:='missing subject'}
  local message=${message:='missing body'}
  local title=${title:='missing title'}
  local priority=${priority:=1}

  [ "$proto" == "$addr" ] && unset proto

  if [ -n "$proto" ]; then
    [ -n "$DEBUG" ] && echo "Template search - $proto/$addr"
    load_template $proto
    [ -n "$DEBUG" ] && echo "Finished search - $proto/$addr"
  fi

  ## add contact protocols here ##
  case $proto in
    prowl)
      [ -n "$url" ] && url_option="-url $url"
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
      echo "unsupported command: [$proto]"
      ;;
  esac
}

# run our main logic
if [ -z "$NAGIOS_NOTIFICATIONTYPE" ]; then
  echo "No NAGIOS environment variables... cannot continue."
  exit 2
else
  determine_contact
fi
