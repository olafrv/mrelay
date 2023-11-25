#!/bin/bash

# set -x # echo on
# debug="-v"

echo "EXTERNAL: Means from OUTSIDE the mail server"
echo "INTERNAL: Means From INSIDE the mail server"
read enter

echo
echo "EXTERNAL: Testing root -> root (local)..."
sendemail $debug -f root@localhost \
  -t root@localhost \
  -u "Test - $(date)" -m "Test with make on $(date)" \
  -s localhost:25
if [ $? -eq 0 ]; then echo "ERROR"; else echo "PASS"; fi
read enter

echo
echo "EXTERNAL: Testing outsider (Spoofing Us) -> authorized outsider (relay) ..."
sendemail $debug -f postmaster@${MRELAY_POSTFIX_DOMAIN} \
  -t postmaster@${MRELAY_POSTFIX_DOMAIN} \
  -u "Test - $(date)" -m "Test with make on $(date)" \
  -s localhost:25
if [ $? -eq 0 ]; then echo "ERROR"; else echo "PASS"; fi
read enter

echo
echo "EXTERNAL: Testing outsider (Spoofing 3rd Party) -> authorized outsider (relay) ..."
sendemail $debug -f john.doe@gmail.com \
  -t postmaster@${MRELAY_POSTFIX_DOMAIN} \
  -u "Test - $(date)" -m "Test with make on $(date)" \
  -s localhost:25
if [ $? -eq 0 ]; then echo "ERROR"; else echo "PASS"; fi
read enter

echo
echo "EXTERNAL: Testing outsider -> NOT authorized outsider (NOT Open Relay) ..."
sendemail $debug -f postmaster@${MRELAY_POSTFIX_DOMAIN} \
  -t postmaster@gmail.com \
  -u "Test - $(date)" -m "Test with make on $(date)" \
  -s localhost:25
if [ $? -eq 0 ]; then echo "ERROR"; else echo "PASS"; fi
read enter

echo
echo "INTERNAL: Testing insider -> authorized outsider (relay+dkim) ..."
docker exec -it mrelay_postfix /bin/bash \
  -c "sendemail $debug -f postmaster@${MRELAY_POSTFIX_DOMAIN} \
  -t postmaster@${MRELAY_POSTFIX_DOMAIN} \
  -u 'Test - $(date)' -m 'Test with make on $(date)' \
  -s localhost:25"
if [ $? -ne 0 ]; then echo "ERROR"; else echo "PASS"; fi
read enter

echo
echo "INTERNAL: Testing root -> authorized outsider (relay) ..."
docker exec -it mrelay_postfix /bin/bash -c "echo 'Test with make on $(date)' | mail -s 'Test - $(date)' postmaster@${MRELAY_POSTFIX_DOMAIN}"
if [ $? -ne 0 ]; then echo "ERROR"; else echo "PASS"; fi
read enter

echo
echo "INTERNAL: Testing root->root (local)..."
docker exec -it mrelay_postfix /bin/bash -c "echo 'Test with make on $(date)' | mail -s 'Test - $(date)' root@localhost"
if [ $? -ne 0 ]; then echo "ERROR"; else echo "PASS"; fi

