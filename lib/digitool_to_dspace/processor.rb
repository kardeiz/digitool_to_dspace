module DigitoolToDspace

  class Processor
  
    class << self
      
      def digital_entity_files(input)
       Dir.glob(File.join(input, 'digital_entities/*.xml'))
      end
      
      def prepare_output(output)
        FileUtils.rm_rf(output) if File.exists?(output)
        sleep 1
        FileUtils.mkdir_p(output) unless File.exists?(output)
      end
      
      
      def process_all(input, output, i = 0)
        raise "Must identify input" if input.nil?
        raise "Must identify output" if output.nil?
        unless DigitoolToDspace.configuration.qdc_properties
          raise "Must identify QDC file"
        end
        prepare_output(output)
        digital_entity_files(input).each do |df|
          de = DigitalEntity.new(df)
          if de.usage_type == "VIEW"
            new(de, i = i.next, output).process
          end
        end
      end
    
    end
  
    def initialize(digital_entity, index, output)
      @digital_entity = digital_entity
      @index = index
      @output = output
    end
    
    def folder
      @folder ||= begin
        folder_name = "item_#{@index.to_s.rjust(3,'0')}"
        File.join(@output, folder_name).tap do |o|
          FileUtils.mkdir_p(o) unless File.exists?(o)
        end
      end
    end
    
    def process
      create_contents
      puts folder
      create_dublin_core
      copy_files
    end
    
    def create_contents
      File.open(File.join(folder, 'contents'), 'w') do |f|
        f.puts @digital_entity.primary_file.contents
      end
    end
    
    def create_dublin_core
      File.open(File.join(folder, 'dublin_core.xml'), 'w') do |f|
        f.puts @digital_entity.dspace_metadata.to_xml
      end
    end
    
    def copy_files
      @digital_entity.primary_file.process(folder)
    end
    
  
  end

end
