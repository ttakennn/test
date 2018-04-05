require '../../src/utils/dockerUtils'
require '../../src/utils/opentsdbUtils'
require '../../src/utils/kafkaUtils'
require '../../src/utils/esUtils'
require '../../src/utils/ymlFileUtils'
require '../../src/constants/constants'
require 'yaml'
require 'logger'
require 'date'

@logger = Logger.new(STDOUT)

def exitWithCondititon(condition, errorMessage)
  if(condition)
    @logger.error(errorMessage)
    exit
  end
end

def validateContainersStatus()
  @logger.info(Constants::WAITING_DOCKER_CONTAINER_MESSAGE)
  sleep(Constants::CONTAINER_DELAY_TIME_IN_SECONDS)
  array_status_failed = []
  Constants::DOCKER_CONTAINER_FAILURE_STATUS.each do |x|
    result = %x( docker ps -f status=#{x} | grep -v 'CONTAINER ID' | awk '{print $1}')
    if !result.empty?
      array_status_failed.push("#{x}")
    end
  end
  if !array_status_failed.empty?
    @logger.error("The status container failed due to #{array_status_failed}")
    exit
  end
end

def checkBundleFailureForContainer(containerName)
  status = %x( docker exec -i #{containerName} bin/client "bundle:list | grep Failure" )
  if !status.empty?
    @logger.info(status)
    system("docker exec -i #{containerName} bin/client \"bundle:list | grep Failure\"")
    @logger.info("Container #{containerName} could not start due to bundle failure")
    exit
  else
    @logger.info("All bundles of #{containerName} are started successfully")
  end
end

def checkBundleGracePeriodForContainer(containerName)
  begin
    Timeout.timeout(Constants::BUNDLE_STATUS_TIME_IN_SECONDS) do
      isGracePeriod = false
      while not isGracePeriod do
        result = %x( docker exec -i #{containerName} bin/client "bundle:list | grep GracePeriod" )
        if !result.empty?
          @logger.info(result)
          @logger.info("All bundles of #{containerName} are not started")
        else
          isGracePeriod = true
        end
        sleep(Constants::BUNDLE_STATUS_DELAY_TIME_IN_SECONDS)
      end
    end
  rescue Timeout::Error
    @logger.error("Cannot deploy container #{containerName} to Karaf due to timeout error")
  end
end

def checkBundleResolvedForContainer(containerName)
  begin
    Timeout.timeout(Constants::BUNDLE_STATUS_TIME_IN_SECONDS) do
      isResolved = false
      while not isResolved do
        result = %x( docker exec -i #{containerName} bin/client "bundle:list | grep Resolved" )
        if !result.empty?
          @logger.info(result)
          @logger.info("All bundles of #{containerName} are not started")
        else
          isResolved = true
        end
        sleep(Constants::BUNDLE_STATUS_DELAY_TIME_IN_SECONDS)
      end
    end
  rescue Timeout::Error
    @logger.error("Cannot deploy container #{containerName} to Karaf due to timeout error")
  end
end

def checkBundleStartingForContainer(containerName)
  begin
    Timeout.timeout(Constants::BUNDLE_STATUS_TIME_IN_SECONDS) do
      isStarting = false
      while not isStarting do
        result = %x( docker exec -i #{containerName} bin/client "bundle:list | grep Starting" )
        if !result.empty?
          @logger.info(result)
          @logger.info("All bundles of #{containerName} are not started")
        else
          isStarting = true
        end
        sleep(Constants::BUNDLE_STATUS_DELAY_TIME_IN_SECONDS)
      end
    end
  rescue Timeout::Error
    @logger.error("Cannot deploy container #{containerName} to Karaf due to timeout error")
  end
end

def checkBundleStatusForInternalContainers()
  Constants::INTERNAL_CONTAINERS.each do |x|
    containerNameExists = %x( docker ps -q -f status=running -f name=#{x} )
    if containerNameExists != nil && containerNameExists != ""
      checkBundleResolvedForContainer("#{x}")
      checkBundleStartingForContainer("#{x}")
      checkBundleGracePeriodForContainer("#{x}")
      checkBundleFailureForContainer("#{x}")
    end
  end
end

def getESPort(ymlFile)
    ports = ymlFile['services']['elasticsearch']['ports']
    return ports.to_s.sub(/:.*$/,"").gsub(/\[\"/,"")
end

def getKafkaPort(ymlFile)
    ports = ymlFile['services']['kafka']['ports']
    return ports.to_s.sub(/:.*$/,"").gsub(/\[\"/,"")
end

def getOpenTSDBPort(ymlFile)
    ports = ymlFile['services']['opentsdb']['ports']
    return ports.to_s.sub(/:.*$/,"").gsub(/\[\"/,"")
end

dockerUtils = DockerUtils.new("../../src/resources/demo.yml")
ymlFileUtils = YMLFileUtils.new 

esUtils = ESUtils.new(Constants::ES_HOST, getESPort(ymlFileUtils.parseYmlFile(dockerUtils.getFilePath)))
opentsdbUtils = OpenTSDBUtils.new(Constants::OPENTSDB_HOST, getOpenTSDBPort(ymlFileUtils.parseYmlFile(dockerUtils.getFilePath)))
kafkaUtils = KafkaUtils.new(Constants::KAFKA_HOST, getKafkaPort(ymlFileUtils.parseYmlFile(dockerUtils.getFilePath)))

@logger.info("1. Cleanup all containers")
dockerUtils.cleanUpAllContainers()

@logger.info("2. Start all containers from yml file")
infoComposeFileMap = dockerUtils.startDockerComposeFile(dockerUtils.getFilePath)
if infoComposeFileMap['isValid'] == true
  isExecuteCommand = dockerUtils.executeCommand("docker-compose -f " + infoComposeFileMap['filePath'] + " up -d")
  if !isExecuteCommand
    @logger.error("Could not execute yml file from docker compose")
    exit
  end
else
  @logger.error(Constants::INVALID_YML_FILE)
  exit
end

@logger.info("3. Check all docker containers are running")
validateContainersStatus()
dockerUtils.checkStatusForAllContainers()
@startTime = DateTime.now
@logger.info("Get startTime: #{@startTime}")

@logger.info("4. Check internal containers login as Karaf")
dockerUtils.checkInternalContainerLoginAsKaraf()

@logger.info("5. Check all bundles of internal containers are active in Karaf")
checkBundleStatusForInternalContainers()

@logger.info("6. Check OpenTSDB connection")
isOpenTsDBConnected = opentsdbUtils.checkOpenTSDBConnection()
exitWithCondititon(!isOpenTsDBConnected, Constants::OPENTSDB_CONNECTION_FAILURE_MSG)
@logger.info(Constants::OPENTSDB_CONNECTION_SUCCESSFULLY_MSG)

@logger.info("7. Create a dummy metric name: 'dummyMetric', value: 50")
opentsdbUtils.createDummyMetric('dummyMetric', 50)

@logger.info("8. Insert a data point for metric: 'dummyMetric', value: 100")
opentsdbUtils.insertDataPoint('dummyMetric', 100)

@logger.info("9. Check Kafka connection")
isKafkaConnected = kafkaUtils.checkKafkaConnection()
exitWithCondititon(!isKafkaConnected, Constants::KAFKA_CONNECTION_FAILURE_MSG)
@logger.info(Constants::KAFKA_CONNECTION_SUCCESSFULLY_MSG)

@logger.info("10. Send notification to Kafka broker")
kafkaUtils.sendMessage("dummyTopicName", "Hello everyone")

@logger.info("11. Receive notification from Kafka broker")
messages = kafkaUtils.receiveMessage("dummyTopicName")
kafkaUtils.printMessages(messages)

@logger.info("12. Delete topic name from Kafka broker")
kafkaUtils.deleteTopicName("dummyTopicName")

@logger.info("13. Check ElasticSearch connection")
isESConnected = esUtils.checkESConnection()
exitWithCondititon(!isESConnected, Constants::ELASTICSEARCH_CONNECTION_FAILURE_MSG)
@logger.info(Constants::ELASTICSEARCH_CONNECTION_SUCCESSFULLY_MSG)

@logger.info("14. Query logs in ElasticSearch")
@logMessages = "Sync for Manager AMS Execution Completed"
@queryString = "{\"query\":{\"bool\":{\"must\":[{\"match_phrase\":{\"message\":\"#{@logMessages}\"}},{\"range\":{\"date\":{\"gte\":\"#{@startTime}\",\"lt\":\"now\"}}}]}}}"
esUtils.queryLogs(@queryString)

@logger.info("15. Stop fnms-syncope to check the containers have failure logs in ES")
system("docker stop fnms-syncope")
esUtils.queryFailureLogs()

@logger.info("16. Start fnms-syncope to check the containers don't have failure logs in ES")
system("docker start fnms-syncope")
esUtils.queryFailureLogs()