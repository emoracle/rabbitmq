echo CN is de user
# Generate client certificate
openssl genrsa -out client_key.pem 2048
openssl req -new -key client_key.pem -out client_csr.pem
openssl x509 -req -days 3650 -in client_csr.pem -CA ca_certificate.pem -CAkey ca_key.pem -CAcreateserial -out client_certificate.pem

chmod 664 *.pem
