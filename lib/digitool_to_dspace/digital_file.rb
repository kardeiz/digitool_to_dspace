module DigitoolToDspace

  class DigitalFile
  
    def initialize(file_path, file_type, usage_type)
      @file_path = file_path
      @file_type = file_type
      @usage_type = usage_type
    end
    
    def contents
      "#{File.basename @file_path}".tap do |o|
        o << "\tpermissions:-r 'Administrator'" if @usage_type == "Archive"
        o << "\tprimary:true\r\n"
      end
    end
    
    def is_image?; @file_type != 'pdf'; end
    
    def magick_object
      @magick_object ||= MiniMagick::Image.open(@file_path)
    end
    
    def dimensions      
      magick_object['dimensions'].tap do |o|
        return "#{o.first}px x #{o.last}px"
      end
    end
    
    def ppi
      magick_object['%x x %y'].gsub(' PixelsPerInch','ppi').gsub(' Undefined','ppi')
    end
    
    def process(folder)
      FileUtils.cp(@file_path, folder)
    end
  
  end
  
end

