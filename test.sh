#!/bin/bash

sendemail -v -f root@localhost \
  -t postmaster@${MRELAY_POSTFIX_DOMAIN} \
  -u "Make Test $(date)" -m "Makes Test $(date)" \
  -s localhost:25
