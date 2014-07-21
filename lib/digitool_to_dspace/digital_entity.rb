module DigitoolToDspace

  class DigitalEntity
  
    class << self
    
      def root
        @root ||= Nokogiri::XML('<root/>').tap do |o|
          o.root.add_namespace 'dcterms', 'http://purl.org/dc/terms/'
          o.root.add_namespace 'dc', 'http://purl.org/dc/elements/1.1/'
          o.root.add_namespace nil, 'http://www.w3.org/2001/XMLSchema-instance'
        end        
      end
      
      def get_node_signature(node)
        {
          name: node.name,
          ns: node.namespace.try(:href),
          attrs: node.attributes.each_with_object({}) do |(k,v), acc|
            acc[k] = v.value
          end
        }
      end
      
      def mappings
        @mappings ||= begin
          r = File.read DigitoolToDspace.configuration.qdc_properties
          r.each_line.with_object({}) do |line, hash|
            next if line.strip[0] == '#' || line !~ /=/
            hash[line.split(/\=/).first.strip] = begin
              node = root.fragment(line.split(/\=/).last.strip).children.first
              get_node_signature(node)
            end
          end
        end
      end
    
    end
  
    def initialize(file_path)
      @file_path = file_path
    end

    def source
      @source ||= File.expand_path('../..', @file_path)
    end
  
    def rep
      @rep ||= Nokogiri::XML(File.read(@file_path))
    end
  
    def dublin_core
      @dublin_core ||= begin
        value = rep.at_xpath('//md[type="dc"]/value')
        Nokogiri::XML(value.content) if value
      end
    end
    
    def dublin_core_parsed
      @dublin_core_parsed ||= begin
        dublin_core.xpath('//dc:*|//dcterms:*', dublin_core.namespaces).each_with_object({}) do |onode, acc|
          onsig = self.class.get_node_signature(onode)
          next unless onname = self.class.mappings.key(onsig)
          next if onode.content.blank?
          acc[onname] ||= []
          acc[onname] << onode.content 
        end
      end
    end
      
    def dc_dates_issued
      Array.wrap(dublin_core_parsed['dc.date']).each_with_object([]) do |date, acc|
        case date
        when /\d{4}/, /\d{4}\-\d{1,2}/, /\d{4}\-\d{1,2}\-\d{1,2}/
          acc << date
        end
      end
    end
  
    def dc_date_captured
      return unless dstr = rep.at_xpath('//control/creation_date').try(:content)
      Time.parse(dstr).strftime('%Y-%m-%d') rescue nil
    end
  
    def extra_metadata
      {}.tap do |o|
        o['dc.identifier.digitool'] = [pid] if pid
        o['dc.date.captured'] = [dc_date_captured] if dc_date_captured
        o['dc.date.issued'] = dc_dates_issued unless dc_dates_issued.empty?
        if primary_file && primary_file.is_image?
          o['dc.format.dimensions'] = [primary_file.dimensions]
          o['dc.format.resolution'] = [primary_file.ppi]
        end
      end
    end
  
    def pid
      @pid ||= rep.at_xpath('//pid').try(:content)
    end
  
    def dspace_metadata
      Nokogiri::XML('<dublin_core/>').tap do |dim_doc|
        hash = dublin_core_parsed.deep_merge(extra_metadata) do |key, old, new|
          if key == 'dc.date.issued' then Array.wrap(new)
          else Array.wrap(old) + Array.wrap(new)
          end
        end
        hash.each do |k, vals|
          vals.each do |val|
            nnode = Nokogiri::XML::Node.new('dcvalue', dim_doc)
            _, elem, qual = k.split('.')
            nnode['element'] = elem
            nnode['qualifier'] = qual || 'none'
            nnode.content = val
            dim_doc.root.add_child nnode
          end
        end
      end
    end
  
    def file
      @file ||= begin
        file_name = rep.at_xpath('//stream_ref/file_name').try(:content)
        if !file_name.blank?
          file_type = rep.at_xpath('//stream_ref/file_extension').try(:content)
          file_path = File.join(source, 'streams', file_name)
          DigitalFile.new(file_path, file_type, usage_type)
        else nil
        end
      end
    end
  
    def usage_type
      @usage_type ||= rep.at_xpath('//control/usage_type').try(:content)
    end
  
    def related_manifestations
      @related_manifestations ||= begin
        pids = rep.xpath('//relations/relation[type/text() = "manifestation"]/pid').map(&:content)
        pids.each_with_object([]) do |pid, acc|
          file = File.expand_path("../#{pid}.xml", @file_path)
          acc << DigitalEntity.new(file) if File.exists?(file)
        end
      end
    end
    
    def primary_file
      de = related_manifestations.detect do |rm|
        rm.usage_type == 'Archive'
      end || self
      de.file
    end
  
  end

end
