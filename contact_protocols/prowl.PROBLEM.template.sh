# export shell vars
# nagios macros are valid
# can also put logic here as well
# priority=1
# url="some url"
message="$NAGIOS_SERVICEDESC"
subject="$NAGIOS_SERVICEDESC on $NAGIOS_HOSTALIAS"
title="$NAGIOS_NOTIFICATIONTYPE "
# if [ "$NAGIOS_SERVICESTATEID" -ge 2 -o "$NAGIOS_HOSTSTATEID" -ge 2 ]; then
  # if [ -z "$priority" ]; then
    # use_priority=2
  # else
    # use_priority=${priority:=1}
  # fi
# fi
