require "digitool_to_dspace/version"
require 'ostruct'
require 'nokogiri'
require 'active_support'
require 'active_support/core_ext'
require 'digitool_to_dspace/digital_entity'
require 'digitool_to_dspace/digital_file'
require 'digitool_to_dspace/processor'
require 'fileutils'
require 'mini_magick'
module DigitoolToDspace
  
  def self.configuration
    @configuration ||= OpenStruct.new
  end

  def self.configure
    yield(configuration) if block_given?
  end
    
  
end

DigitoolToDspace.configure do |conf|
  conf.qdc_properties = "/home/jhbrown/projects/dspace4/config/crosswalks/QDC.properties"
end


