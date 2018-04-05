require 'net/https'
require 'uri'
require 'rubygems'
require 'json'
require 'timeout'
require 'logger'
require 'date'
require '../../src/constants/constants'

class ESUtils

  def initialize(ip, port)
    @ip = ip
    @port = port
    @containerNotWorkProperly = []
    @logger = Logger.new(STDOUT)
  end

  # return 200 if connect to ES successfully
  def checkESConnection()
    uri = URI("http://#{@ip}:#{@port}/_cat/health?h=st")
    request = Net::HTTP.get_response(uri)
    return request.kind_of? Net::HTTPSuccess
  end

  def getFailureLogMessagesFromInternalContainer
     mappingInternalContainerLogMessages = Hash.new
     nacContainerLogMessageArray = Array.new

     nacContainerLogMessageArray.push("error while trying to connect to syncope")
     nacContainerLogMessageArray.push("Opentsdb is disconnected")
     nacContainerLogMessageArray.push("sqlDbDisconnectedHaCondition has gone to CRITICAL state.")
     mappingInternalContainerLogMessages["nac"] = nacContainerLogMessageArray

     anvContainerLogMessageArray = Array.new
     anvContainerLogMessageArray.push("error while trying to connect to syncope")
     anvContainerLogMessageArray.push("sqlDbDisconnectedHaCondition has gone to CRITICAL state.")
     anvContainerLogMessageArray.push("Consumer-brokers connection is down")
     mappingInternalContainerLogMessages["anv-docker"] = anvContainerLogMessageArray

     ncLiveCollectorContainerLogMessageArray = Array.new
     ncLiveCollectorContainerLogMessageArray.push("error while trying to connect to syncope")
     ncLiveCollectorContainerLogMessageArray.push("Opentsdb is disconnected")
     ncLiveCollectorContainerLogMessageArray.push("sqlDbDisconnectedHaCondition has gone to CRITICAL state.")
     ncLiveCollectorContainerLogMessageArray.push("Consumer-brokers connection is down")
     mappingInternalContainerLogMessages["nc-live-collector"] = ncLiveCollectorContainerLogMessageArray

     alarmEsBrigeContainerLogMessageArray = Array.new
     alarmEsBrigeContainerLogMessageArray.push("Opentsdb is disconnected")
     alarmEsBrigeContainerLogMessageArray.push("sqlDbDisconnectedHaCondition has gone to CRITICAL state.")
     alarmEsBrigeContainerLogMessageArray.push("Consumer-brokers connection is down")
     mappingInternalContainerLogMessages["alarm-es-bridge"] = alarmEsBrigeContainerLogMessageArray

     healthCalculatorContainerLogMessageArray = Array.new
     healthCalculatorContainerLogMessageArray.push("Opentsdb is disconnected")
     healthCalculatorContainerLogMessageArray.push("sqlDbDisconnectedHaCondition has gone to CRITICAL state.")
     mappingInternalContainerLogMessages["health-calculator"] = healthCalculatorContainerLogMessageArray

     return mappingInternalContainerLogMessages
  end

  # search log messages in ES
  def queryLogs(queryString)
      result = %x( curl --silent http://#{@ip}:#{@port}/_search -XPOST -d \'#{queryString}\' )
      json = JSON.parse(result)
      total = json['hits']['total']
      getJsonFromQueryString = JSON.parse(queryString)
      messages = getJsonFromQueryString["query"]["bool"]["must"][0]['match_phrase']['message']
      if total > 0
         @logger.info("Successfully. Found logs \'#{messages}\' in ElasticSearch")
      else
         @logger.error("Could not find log \'#{messages}\' in ElasticSearch")
      end
  end

  # searching failure log messages in ES
  def queryFailureLogs()
     @logger.info("Searching ...")
     sleep(60) # Timeout 60s to wait failure logs show in ES when we stop or start the internal container
     getFailureLogMessagesFromInternalContainer.each do |container, failureLogMessageLists|
        failureLogMessageLists.each do |failureLogMessage|
          @logger.info("Checking logs \'#{failureLogMessage}\' for the container \'#{container}\' ...")
          result = %x( curl --silent http://#{@ip}:#{@port}/_search -XPOST -d '{"query":{"bool":{"must":[{"match_phrase":{"message":"#{failureLogMessage}"}},{"range":{"date":{"gte":"now-#{Constants::PERIOD_TIME_IN_SECONDS}","lt":"now"}}}]}}}' | grep -o '"container_name":"#{container}"' )
          if result.length > 0
              @logger.info("Successfully. Found log \'#{failureLogMessage}\' in the container \'#{container}\'.The container \'#{container}\' could not work properly")
          else
              @logger.info("Not found log \'#{failureLogMessage}\' in the container \'#{container}\'")
          end
        end
     end
  end

end