#!/bin/bash

s_flag=""
if [ ! -z "${MRELAY_POSTFIX_RELAYHOST}" ]; then
  s_flag=$(echo "-s ${MRELAY_POSTFIX_RELAYHOST}" | sed 's/\[//g' | sed 's/\]//g')
fi

sendemail -v -f root@localhost \
  -t postmaster@${MRELAY_POSTFIX_DOMAIN} \
  -u "Make Test $(date)" -m "Makes Test $(date)" $s_flag
