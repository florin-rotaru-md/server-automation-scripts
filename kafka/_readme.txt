Install Confluent.Kafka

dotnet add package Confluent.Kafka

// Producer

using Confluent.Kafka;

var config = new ProducerConfig
{
    BootstrapServers = "localhost:9092"
};

using var producer = new ProducerBuilder<Null, string>(config).Build();

var topic = "test-topic";

for (int i = 0; i < 5; i++)
{
    var value = $"Mesaj {i}";
    var result = await producer.ProduceAsync(topic, new Message<Null, string> { Value = value });
    Console.WriteLine($"Trimis: {value} | Partition: {result.Partition} | Offset: {result.Offset}");
}


// Consumer

using Confluent.Kafka;

var config = new ConsumerConfig
{
    BootstrapServers = "localhost:9092",
    GroupId = "test-consumer-group",
    AutoOffsetReset = AutoOffsetReset.Earliest
};

using var consumer = new ConsumerBuilder<Ignore, string>(config).Build();

consumer.Subscribe("test-topic");

Console.WriteLine("Ascultare mesaje... Ctrl+C pentru oprire");

try
{
    while (true)
    {
        var cr = consumer.Consume();
        Console.WriteLine($"Primit: {cr.Message.Value} | Partition: {cr.Partition} | Offset: {cr.Offset}");
    }
}
catch (OperationCanceledException)
{
    consumer.Close();
}



run => docker-compose up -d
open => UI http://localhost:8080 and create test-topic
run Producer .NET – check messages in Kafka UI
run Consumer .NET – check processed messages
	
	
🧪 Other tests
# send message
docker exec -it kafka-kraft kafka-console-producer.sh --topic test --bootstrap-server localhost:9092

# receive message
docker exec -it kafka-kraft kafka-console-consumer.sh --topic test --from-beginning --bootstrap-server localhost:9092
