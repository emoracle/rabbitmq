echo CN moet de serverhost zijn

# Generate server certificate
openssl genrsa -out server_key.pem 2048
openssl req -new -key server_key.pem -out server_csr.pem
openssl x509 -req -days 3650 -in server_csr.pem -CA ca_certificate.pem -CAkey ca_key.pem -CAcreateserial -out server_certificate.pem

