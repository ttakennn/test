require 'net/https'
require 'uri'
require 'date'
require 'json'
require 'logger'
require '../../src/constants/constants'

class OpenTSDBUtils

  def initialize(ip, port)
    @ip = ip
    @port = port
    @logger = Logger.new(STDOUT)
  end

  def checkOpenTSDBConnection()
    uri = URI("http://#{@ip}:#{@port}/")
    request = Net::HTTP.get_response(uri)
    return request.kind_of? Net::HTTPSuccess
  end

  def createDummyMetric(metricName, value)
    uri = URI("http://#{@ip}:#{@port}/api/put?details")
    header = {
        'Content-Type': 'text/plain,application/json'
    }
    data = {
        "metric": "#{metricName}",
        "tags": {
            "objectID": "dummyObjectID",
            "objectType": "dummyObjectType"
        },
        "timestamp": "#{DateTime.now.strftime('%Q')}",
        "value": value
    }

    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Post.new(uri.request_uri, header)
    request.body = data.to_json
    response = http.request(request)

    if response.kind_of? Net::HTTPSuccess
      @logger.info("Create #{metricName} metric successfully")
    else
      @logger.error("Could not create #{metricName} metric")
    end
  end

  def insertDataPoint(metricName, value)
    isInvalid = invalidMetricName(metricName)
    if !isInvalid
      @logger.error("The metric name #{metricName} is not exists")
      exit
    end
    header = {
        'Content-Type': 'text/plain,application/json'
    }
    data = {
        "metric": "#{metricName}",
        "tags": {
            "objectID": "dummyObjectID",
            "objectType": "dummyObjectType"
        },
        "timestamp": "#{DateTime.now.strftime('%Q')}",
        "value": value
    }
    uri = URI("http://#{@ip}:#{@port}/api/put?details")
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Post.new(uri.request_uri, header)
    request.body = data.to_json
    response = http.request(request)

    if response.kind_of? Net::HTTPSuccess
      @logger.info("Insert #{metricName} data point metric successfully")
    else
      @logger.error("Could not insert #{metricName} data point metric")
    end
  end

  def invalidMetricName(metricName)
    uri = URI("http://#{@ip}:#{@port}/api/search/lookup?m=#{metricName}")
    request = Net::HTTP.get_response(uri)
    return (request.kind_of? Net::HTTPSuccess)
  end

end