#!/bin/bash
VAULTHOST=$1
/bin/curl -L https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64 > /bin/jq
chmod +x /bin/jq
AUTH_TOKEN=$(/bin/curl -X POST -k "https://$VAULTHOST:8200/v1/auth/aws-ec2/login" -d '{"role":"example","pkcs7":"'$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/pkcs7 | tr -d '\n')'"}' | tee /tmp/response | /bin/jq .auth.client_token | tr -d \")
if [ "$?" -eq "0" ] && [ ! -z "$AUTH_TOKEN" ]; then
  sleep 10
  MYSQL_PASSWORD=$(/bin/curl -H "X-Vault-Token: $AUTH_TOKEN" -k -X GET https://$VAULTHOST:8200/v1/mysql/config/connection | tee /tmp/response2 | /bin/jq .data.connection_url | awk -F\: '{print $2}' | awk -F\@ '{print $1}')
    if [ "$?" -eq "0" ] && [ ! -z "$MYSQL_PASSWORD" ]; then
      /bin/mysql -u root mysql -e "SET PASSWORD FOR 'vault'@'%' = PASSWORD('$MYSQL_PASSWORD'); FLUSH PRIVILEGES;"
      if [ "$?" -eq "0" ]; then
        exit 0
      else
	echo "SET PASSWORD command in mysql failed"
        exit 1
     fi
   else
     echo "MySQL Password couldn't be retrieved from the vault"
     exit 1
   fi
else
  echo "Vault token couldn't be obtained"	
  exit 1
fi
