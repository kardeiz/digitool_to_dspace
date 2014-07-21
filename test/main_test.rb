require 'minitest'
require 'minitest/spec'
require 'minitest/autorun'
require 'digitool_to_dspace'

describe "Main tests" do

#  let(:a_file) { 
#    DigitoolToDspace::Processor.digital_entity_files.first
#  }

#  it "should print my dc" do
#    a = DigitoolToDspace::DigitalEntity.new(a_file)
#    puts a.dspace_metadata.to_xml
#  end

  it "should process my files" do
    DigitoolToDspace::Processor.process_all('/mnt/shared3/bfp', '/mnt/shared3/bfp/out')
  end

end
