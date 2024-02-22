# Generate CA certificate
echo Make shure the CN is the organisation

openssl genrsa -out ca_key.pem 2048
openssl req -new -x509 -days 3650 -key ca_key.pem -out ca_certificate.pem

