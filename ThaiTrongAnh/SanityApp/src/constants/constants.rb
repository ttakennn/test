class Constants

  #File constants
  YML_EXTENSION                            = [".yml"]

  # Config hosts and ports
  DUMMY_TOPIC_NAME                         = "dummyTopicName"
  KAFKA_HOST                               = "localhost"
  ES_HOST                                  = "localhost"
  OPENTSDB_HOST                            = "localhost"

  # Message constants
  DOCKER_CONTAINER_RUNNING_MESSAGE         = "All docker containers are running successfully"
  DOCKER_CONTAINER_NOT_RUNNING_MSG         = "All docker containers are not running"
  WAITING_DOCKER_CONTAINER_MESSAGE         = "Waiting for all docker containers started ..."
  ELASTICSEARCH_CONNECTION_FAILURE_MSG     = "Could not connection to ES server"
  ELASTICSEARCH_CONNECTION_SUCCESSFULLY_MSG= "Connect to ES successfully"
  OPENTSDB_CONNECTION_FAILURE_MSG          = "Could not connect to OpenTSDB"
  OPENTSDB_CONNECTION_SUCCESSFULLY_MSG     = "Connect to OpenTSDB successfully"
  CLEANUP_OLD_DOCKER_CONTAINER_MSG         = "Clean up old docker containers ..."
  INVALID_YML_FILE                         = "Invalid yml file format"
  KAFKA_CONNECTION_FAILURE_MSG             = "Could not connection to Kafka server"
  KAFKA_CONNECTION_SUCCESSFULLY_MSG        = "Connect to Kafka server successfully"

  # Time constants
  BUNDLE_STATUS_DELAY_TIME_IN_SECONDS      = 15
  LOGIN_KARAF_DELAY_TIME_IN_SECONDS        = 10
  CONTAINER_DELAY_TIME_IN_SECONDS          = 30
  CONTAINER_RETRY_TIME_IN_SECONDS          = 10
  CONTAINER_LOGIN_KARAF_TIME_IN_SECONDS    = 600
  BUNDLE_STATUS_TIME_IN_SECONDS            = 120
  SEARCH_LOG_TIME_IN_SECONDS               = 60
  PERIOD_TIME_IN_SECONDS                   = "30s"

  # Docker container constants
  CLEANUP_DOCKER_CONTAINERS_COMMAND        = "docker rm -f $(docker ps -a -q)"
  CONTAINER_RUNNING_COMMAND                = "docker ps -f status=running | grep -v 'CONTAINER ID' | awk '{print $1}'"
  INTERNAL_CONTAINERS                      = ["anv-docker", "nac", "oad2kafka","alarm-es-bridge","ipfix-backend-collector","ipfix-frontend-collector","nc-live-collector-nac","nc-live-collector","health-calculator"]
  DOCKER_CONTAINER_FAILURE_STATUS          = ["created", "restarting", "paused", "exited", "dead"]
end
