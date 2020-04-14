## Using Letsencrypt to obtain and install free TLS/SSL certificates

1. [Install certbot](https://certbot.eff.org/instructions)
   
   Mac
   ```
   sudo brew install certbot
   ```
   Centos 7
   ```bash
   sudo yum install epel-release
   sudo yum install certbot python2-certbot-apache mod_ssl
   ```
   
2. Obtain the certificate using the following utility
   ```
   EMAIL=adesireddy@dummy.com
   DNS_NAME=*.avinash.dockerps.io

   certbot certonly \
    --manual \
    --preferred-challenges=dns \
    --email ${EMAIL} \
    --agree-tos \
    --config-dir ./letsencrypt/config \
    --logs-dir ./letsencrypt/logs \
    --work-dir ./letsencrypt/workdir \
    -d ${DNS_NAME}
   ```
   Follow the additional instructions to verify the entries.

3. Navigate and verify - https://mxtoolbox.com/TXTLookup.aspx
