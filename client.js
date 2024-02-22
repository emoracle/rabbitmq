const amqp = require('amqplib');
const fs = require('fs');

const sslOptions = {
    cert: fs.readFileSync('/home/edwin/rabbitmq/certs/client_certificate.pem'),
    key: fs.readFileSync('/home/edwin/rabbitmq/certs/client_key.pem'),
    ca: [fs.readFileSync('/home/edwin/rabbitmq/certs/ca_certificate.pem')],
    rejectUnauthorized: false // This is necessary only if the server uses the self-signed certificate
};

async function consumeFromQueue(queueName) {
    try {
        // Connect to RabbitMQ server with SSL
        const connection = await amqp.connect({
            protocol: 'amqps',
            hostname: 'localhost',
            port: 5671,
            username: 'user',
            password: 'password',
            //vhost: 'bedrijf1',
            connectionOptions: sslOptions,
            rejectUnauthorized: false
        });

        // Create a channel
        const channel = await connection.createChannel();

        // Ensure the queue exists
        const queueCheck = await channel.assertQueue(queueName, {
            durable: true // Matches the producer's queue durability
        });

        channel.prefetch(5);
        // Log if the queue already exists, if messageCount is provided, the queue was existing)
        if (queueCheck.messageCount !== undefined) {
            console.log(`Queue ${queueName} already exists with ${queueCheck.messageCount} messages`);
        } else {
            console.log(`Queue ${queueName} created.`);
        }

        console.log(" [*] Waiting for messages in %s. To exit press CTRL+C", queueName);

        // Consume messages from the queue
        channel.consume(queueName, function (msg) {
            if (msg !== null) {
                console.log(`Headers: ${JSON.stringify(msg.properties.headers)} `);
                console.log(" [x] Received %s", msg.content.toString());

                // Acknowledge the message, noAck must be false
                channel.ack(msg);
            }
        }, {
            noAck: false
        });
    } catch (error) {
        console.error("Error consuming message from queue:", error);
    }
}

// Define the queue name from which to consume messages
const queueName = 'testQueue';

// Call the function to start consuming messages
consumeFromQueue(queueName);
