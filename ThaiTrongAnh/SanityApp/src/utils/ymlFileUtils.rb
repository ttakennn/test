require '../../src/constants/constants'
require 'yaml'
require 'logger'

class YMLFileUtils
  
  def initialize
    @logger = Logger.new(STDOUT)
  end

  def isValidYmlFile(filePath)
    ymlFilePath = File.new("#{filePath.chomp}").path
    if ymlFilePath != nil && ymlFilePath != ""
      return Constants::YML_EXTENSION.include? File.extname(ymlFilePath)
    end
    return false
  end

  def parseYmlFile(filePath)
  	 ymlFile = YAML.load_file(filePath)
     if !ymlFile.empty?
  	    return ymlFile
     else
        @logger.error("Could not load yml file")
     end
  end

end
