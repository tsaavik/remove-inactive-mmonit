#!/bin/bash
#
# remove-inactive-mmonit v1.0
# David Mcanulty
# Requires Bash 4.0, curl and python (for json)


# You will need to change these 2 variables for this to work
z_username=YOUR_MMONIT_USERNAME
mmonit_url="http://mmonit.YOURDOMAIN.COM:8888"


mmonit_cookie=~/.mmonit/cookie
silent="--silent"

read -sp "Please enter ${z_username}'s password for mmonit at ${mmonit_url}: " z_password

# Cookies expire, delete cookie older then 1 hour
find ${mmonit_cookie} -mmin +60 -delete

# Get cookies - only needs to run once
if [[ -f ${mmonit_cookie} ]] ;then
   : #we have a cookie, good
else
   mkdir -pm 0700 ~/.mmonit
   curl ${silent} -c ${mmonit_cookie} ${mmonit_url}/index.csp
fi

# Turn off mmonit security check so we don't have to logon each time - https://mmonit.com/documentation/http-api/Examples/cURL
curl ${silent} -b ${mmonit_cookie}  -d z_username=${z_username} -d z_password=${z_password} -d z_csrf_protection=off ${mmonit_url}/z_security_check

# get a list of all inactive servers and pretty print the json for easy parsing - https://mmonit.com/documentation/http-api/Methods/Admin_Hosts
#
# Format of json return is
#   "hostname": "10-10-30-12.us-west-3.compute.internal",
#            "id": 53463518,
#            "ipaddr": "10.10.30.12",
#            "monitversion": "5.6",
#           "status": "Inactive"

# Format of json return after egrep/sed is
#            hostname: 10-10-30-12.us-west-3.compute.internal
#            id: 15596128,
#            hostname: 10-10-30-13.us-west-3.compute.internal
#            id: 16665867

i=0
while read hostname_key hostname_value; read id_key id_value; read ipaddr_key ipaddr_value; read monitversion_key monitversion_value; read status_key status_value; do
  if [[ $status_value = "Inactive" ]] ;then
     printf 'hostname key: (%s) value: (%s)' "$hostname_key" "$hostname_value"
     printf ' id key: (%s) value: (%s)' "$id_key" "$id_value"
     printf 'status key: (%s) value: (%s)\n' "$status_key" "$status_value"
     ((i++))
  fi
  curl ${silent} -b ${mmonit_cookie} -d id=${id_value} -d monituser=${z_username} -d monitpassword=${z_password} ${mmonit_url}/admin/hosts/delete
done < <(curl ${silent} -b ${mmonit_cookie} ${mmonit_url}/admin/hosts/list |python -mjson.tool |grep -B4 Inactive |grep -v "\-\-" |sed -e 's/"\|,//g')

echo "$i inactive hosts removed"
