#!/bin/bash

sendemail -v -f root@localhost \
  -t postmaster@${MRELAY_POSTFIX_DOMAIN} \
  -u "Test - $(date)" -m "Test with make on $(date)" \
  -s localhost:25
