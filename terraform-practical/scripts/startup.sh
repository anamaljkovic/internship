#!/bin/bash

set -e
apt-get update -y
apt-get install -y apache2

HOSTNAME=$(hostname)
cat > /var/www/html/index.html <<EOF
<!DOCTYPE html>
<html>
<head><title>Terraform practical</title></head>
<body>
  <h1>Served by: ${HOSTNAME}</h1>
  <p>This instance is part of MIG.</p>
</body>
</html>
EOF

systemctl enable apache2
systemctl restart apache2

touch /var/tmp/provisioning_complete