require 'rubygems'
require 'kafka'
require 'logger'

class KafkaUtils

  def initialize(ip, port)
    @ip = ip
    @port = port
    @default_partition_value = 0
    @default_offset_value = 0
    @paused_partitions = {}
    @logger = Logger.new(STDOUT)
  end

  def checkKafkaConnection()
    #For locally, just execute bin/date inside kafka container
    return system("docker exec -it kafka bin/date")
  end

  def createTopicName(topicName)
     begin
        result = system("docker exec -it kafka bin/kafka-topics --create --zookeeper zookeeper:2181 --replication-factor 1 --partitions 1 --topic #{topicName}")
        if result 
          @logger.info("Created topic name is #{topicName}")
        end
     rescue
        @logger.error("Could not create topic name")
     end  
  end

  def sendMessage(topicName, message)
    begin
      checkTopicName = %x( docker exec -it kafka bin/kafka-topics --zookeeper zookeeper:2181 --describe --topic #{topicName} )
      if !checkTopicName.empty?
        kafka = Kafka.new(["#{@ip}:#{@port}"], client_id: "app99")
        kafka.deliver_message("#{message}", topic: "#{topicName}")
        @logger.info("Send messages to Kafka broker successfully")
      else
        @logger.info("Topic name not exists. Create a topic name \'#{topicName}\'")
        createTopicName(topicName)
        kafka = Kafka.new(["#{@ip}:#{@port}"], client_id: "app99")
        kafka.deliver_message("#{message}", topic: "#{topicName}")
        @logger.info("Send messages to Kafka broker successfully")
      end
    rescue
      @logger.error("Could not send message from broker")
    end
  end

  def receiveMessage(topicName)
    begin
        checkTopicName = %x( docker exec -it kafka bin/kafka-topics --zookeeper zookeeper:2181 --describe --topic #{topicName} )
        if !checkTopicName.empty?
            kafka = Kafka.new(["#{@ip}:#{@port}"])
            messages = kafka.fetch_messages(
              topic: topicName,
              partition: @default_partition_value,
              offset: @default_offset_value
            )
          @logger.info("Receive messages from Kafka broker successfully")
          return messages
        else
          @logger.error("Topic name \'#{topicName}\' is not exists")
        end
     rescue
          @logger.error("Could not receive message from Kafka server")
     end
  end

  def deleteTopicName(topicName)
     begin
        @logger.info("Delete topic name #{topicName}")
        %x( docker exec -it kafka bin/kafka-topics --delete --zookeeper zookeeper:2181 --topic #{topicName} )
        %x( docker restart kafka )
     rescue
        @logger.error("Could not delete topic name")
     ensure 
        sleep(5)
     end
  end

  def printMessages(messages)
    begin
        messages.each do |message|
          @logger.info(message.value)
        end
    rescue
        @logger.error("Could not print message from broker")
    end
  end
end