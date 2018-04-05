require '../../src/constants/constants'
require '../../src/utils/ymlFileUtils'
require 'timeout'
require 'logger'

class DockerUtils

  def initialize(filePath)
     @filePath = filePath
     @logger = Logger.new(STDOUT)
  end

  def getFilePath
      @filePath
  end

  def executeCommand(command)
    return system(command)
  end

  def executeKarafCommand(containerName, karafCommand)
    return executeCommand("docker exec -i "+ containerName + " bin/client " + karafCommand)
  end

  def cleanUpAllContainers()
    return executeCommand(Constants::CLEANUP_DOCKER_CONTAINERS_COMMAND)
  end

  def startDockerComposeFile(filePath)
    ymlFileUtils = YMLFileUtils.new
    isValid = ymlFileUtils.isValidYmlFile(filePath)
    if isValid
       infoComposeFileMap = Hash["filePath" => "#{filePath}", "isValid" => isValid]
       return infoComposeFileMap
    else
      @logger.error("The yml file invalid")
    end
  end

  def checkStatusForAllContainers()
    result = executeCommand(Constants::CONTAINER_RUNNING_COMMAND)
    if result
      @logger.info(Constants::DOCKER_CONTAINER_RUNNING_MESSAGE)
    else
      @logger.error(Constants::DOCKER_CONTAINER_NOT_RUNNING_MSG)
    end
  end

  def checkInternalContainerLoginAsKaraf()
    begin
      #Set timeout 10 minutes to make sure that containers could start successfully
      containerName = ""
      Timeout.timeout(Constants::CONTAINER_LOGIN_KARAF_TIME_IN_SECONDS) do
        Constants::INTERNAL_CONTAINERS.each do |x|
          containerNameExists = %x( docker ps -q -f status=running -f name=#{x} )
          if containerNameExists != nil && containerNameExists != ""
            iStart = false
            while not iStart do
              result = executeCommand("docker exec -i #{x} bin/status")
              if result
                @logger.info("Login to Karaf for #{x} container successfully")
                iStart = true
              else
                @logger.error(%x( docker exec -i #{x} bin/status ))
                @logger.error("Cannot login to Karaf for #{x} container")
              end
              sleep(Constants::LOGIN_KARAF_DELAY_TIME_IN_SECONDS)
            end
          end
          containerName = "#{x}"
        end
      end
    rescue Timeout::Error
      @logger.error("Cannot execute container #{containerName} due to timeout error")
    end
  end

end
