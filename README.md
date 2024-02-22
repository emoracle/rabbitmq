Combined nodejs application and shell scripts to set up a by SSL secured
rabbitmq containerized environment

### ./bin/startRabbitContainer.sh
Create an docker volume for persistent storage and start a docker container with rabbitmq with SSL enabled.

The certs are not included, they should be created by the shell scripts in the bin directory

### producerToExchange.js
Push a producer persistent to an exchange. Create the exchange if it doesn't exists

### producerToQueue.js
Push a producer persistent to an queue. Create the queue if it doesn't exists

### client.js
Receive the messages from te queue.

