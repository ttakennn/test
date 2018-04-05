require '../../src/utils/esUtils'
require '../../src/utils/dockerUtils'
require '../../src/utils/ymlFileUtils'
require '../../src/constants/constants'

def getESPort(ymlFile)
    ports = ymlFile['services']['elasticsearch']['ports']
    return ports.to_s.sub(/:.*$/,"").gsub(/\[\"/,"")
end

dockerUtils = DockerUtils.new("../../src/resources/demo.yml")
ymlFileUtils = YMLFileUtils.new 
esUtils = ESUtils.new(Constants::ES_HOST, getESPort(ymlFileUtils.parseYmlFile(dockerUtils.getFilePath)))
esUtils.queryFailureLogs()


