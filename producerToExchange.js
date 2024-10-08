const amqp = require('amqplib');
const fs = require('fs');

const sslOptions = {
    cert: fs.readFileSync('/home/edwin/rabbitmq/certs/client_certificate.pem'),
    key: fs.readFileSync('/home/edwin/rabbitmq/certs/client_key.pem'),
    ca: [fs.readFileSync('/home/edwin/rabbitmq/certs/ca_certificate.pem')],
    rejectUnauthorized: false // This is necessary only if the server uses the self-signed certificate
};

async function sendToQueue(queueName, exchangeName, routingKey, message) {
    try {
        // Connect to RabbitMQ server
        const connection = await amqp.connect({
            protocol: 'amqps',
            hostname: 'localhost',
            port: 5671,
            username: 'user',
            password: 'password',
            //vhost: 'bedrijf1',
            connectionOptions: sslOptions
        });
        // Non-ssl const connection = await amqp.connect('amqp://user:password@localhost/bedrijf1');  // We sturen het naar een specifieke VHOST bedrijf*

        // Create a channel
        const channel = await connection.createChannel();

        // Assert the exchange (it creates the exchange if it doesn't exist)
        await channel.assertExchange(exchangeName, 'direct', {
            durable: true // Change this as needed; for example, 'fanout' for a fanout exchange
        });

        // Ensure the queue exists, if not, it will be created
        const queueCheck = await channel.assertQueue(queueName, {
            durable: true // Marks the queue as durable; messages will not be persisted to disk when this is false
        });

        // Bind the queue to the exchange
        await channel.bindQueue(queueName, exchangeName, routingKey);

        console.log(`Queue ${queueName} is bound to exchange ${exchangeName} with routing key ${routingKey}`);

        // Log if the queue already exists (assuming if messageCount is provided, the queue was existing)
        if (queueCheck.messageCount !== undefined) {
            console.log(`Queue ${queueName} already exists with ${queueCheck.messageCount} messages`);
        } else {
            console.log(`Queue ${queueName} created.`);
        }

        // Add a timestamp to the message
        const messageWithTimestamp = {
            ...message,
            timestamp: new Date().toISOString() // ISO 8601 format
        };

        const options = {
            mandatory: true,
            headers: {
                "x-bla": "5000"
            }
        };

        channel.publish(exchangeName, routingKey, Buffer.from(JSON.stringify(messageWithTimestamp)), options);

        console.log(" [x] Sent %s", JSON.stringify(messageWithTimestamp));

        // Close the connection and exit
        setTimeout(() => {
            connection.close();
            process.exit(0);
        }, 500);
    } catch (error) {
        console.error("Error sending message to exchange:", error);
    }
}

// Define the names and the message to send
const queueName = 'testQueue';
const message = { text: "Hello, RabbitMQ!" };
const exchangeName = 'exampleExchange';
const routingKey = 'exampleKey';

// Call the function to send the message
sendToQueue(queueName, exchangeName, routingKey, message);
