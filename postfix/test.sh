#!/bin/bash

# set -x # echo on
# debug="-v"
validUser=admin # != postmaster

echo "EXTERNAL: Means from OUTSIDE the mail server"
echo "INTERNAL: Means From INSIDE the mail server"
read -p "Press enter..." enter

echo "STARTED"

echo
echo "EXTERNAL: Outsider (Spoofing root) -> root (local)..."
sendemail $debug -f root@localhost \
  -t root@localhost \
  -u "Test - $(date)" -m "Test with make on $(date)" \
  -s localhost:25
if [ $? -eq 0 ]; then echo "ERROR"; else echo "PASS"; fi  # Deny
read -p "Press enter..." enter

echo
echo "EXTERNAL: Outsider (Spoofing ${MRELAY_POSTFIX_DOMAIN}) -> authorized outsider (relay) ..."
sendemail $debug -f postmaster@${MRELAY_POSTFIX_DOMAIN} \
  -t $validUser@${MRELAY_POSTFIX_DOMAIN} \
  -u "Test - $(date)" -m "Test with make on $(date)" \
  -s localhost:25
if [ $? -eq 0 ]; then echo "ERROR"; else echo "PASS"; fi  # Deny
read -p "Press enter..." enter

echo
dig +short TXT _dmarc.gmail.com
echo "EXTERNAL: Outsider (Spoofing @gmail.com) -> Authorized relay ..."
sendemail $debug -f john.doe@gmail.com \
  -t $validUser@${MRELAY_POSTFIX_DOMAIN} \
  -u "Test - $(date)" -m "Test with make on $(date)" \
  -s localhost:25
if [ $? -ne 0 ]; then echo "ERROR"; else echo "PASS"; fi  # Allowed p=none!
read -p "Press enter..." enter

echo
# search the DMARC record
dig +short TXT _dmarc.microsoft.com
echo "EXTERNAL: Outsider (Spoofing @microsoft.com) -> Authorized relay ..."
sendemail $debug -f john.doe@microsoft.com \
  -t $validUser@${MRELAY_POSTFIX_DOMAIN} \
  -u "Test - $(date)" -m "Test with make on $(date)" \
  -s localhost:25
if [ $? -eq 0 ]; then echo "ERROR"; else echo "PASS"; fi  # Deny
read -p "Press enter..." enter

echo
echo "EXTERNAL: Outsider -> NOT authorized relay (Open Relay) ..."
sendemail $debug -f postmaster@${MRELAY_POSTFIX_DOMAIN} \
  -t postmaster@gmail.com \
  -u "Test - $(date)" -m "Test with make on $(date)" \
  -s localhost:25
if [ $? -eq 0 ]; then echo "ERROR"; else echo "PASS"; fi  # Deny
read -p "Press enter..." enter

echo
echo "INTERNAL: Insider -> Authorized relay (DKIM Signature) ..."
docker exec -it mrelay_postfix /bin/bash \
  -c "sendemail $debug -f postmaster@${MRELAY_POSTFIX_DOMAIN} \
  -t $validUser@${MRELAY_POSTFIX_DOMAIN} \
  -u 'Test - $(date)' -m 'Test with make on $(date)' \
  -s localhost:25"
if [ $? -ne 0 ]; then echo "ERROR"; else echo "PASS"; fi  # Allow 
read -p "Press enter..." enter

echo
echo "INTERNAL: Insider (root) -> Authorized relay (DKIM Signature) ..."
docker exec -it mrelay_postfix /bin/bash -c "echo 'Test with make on $(date)' | mail -s 'Test - $(date)' $validUser@${MRELAY_POSTFIX_DOMAIN}"
if [ $? -ne 0 ]; then echo "ERROR"; else echo "PASS"; fi  # Allow
read -p "Press enter..." enter

echo
echo "INTERNAL: Insider (root) -> Local (root)..."
docker exec -it mrelay_postfix /bin/bash -c "echo 'Test with make on $(date)' | mail -s 'Test - $(date)' root@localhost"
if [ $? -ne 0 ]; then echo "ERROR"; else echo "PASS"; fi  # Allow
read -p "Press enter..." enter

echo "FINISHED"
