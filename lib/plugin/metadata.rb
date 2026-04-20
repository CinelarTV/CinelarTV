# frozen_string_literal: true

module Plugin
  class Metadata
    attr_accessor :name, :version, :authors, :url, :required_version

    def self.parse(content)
      instance = new
      
      content.each_line do |line|
        # Skip frozen_string_literal directive
        next if line.strip == '# frozen_string_literal: true'
        
        # Stop parsing at first non-comment line
        break unless line.start_with?('#')
        
        # Parse metadata fields
        if line =~ /^#\s*(\w+):\s*(.+)$/i
          key, value = $1.downcase, $2.strip
          case key
          when 'name'
            instance.name = value
          when 'version'
            instance.version = value
          when 'authors'
            instance.authors = value
          when 'url'
            instance.url = value
          when 'required_version'
            instance.required_version = value
          end
        end
      end
      
      instance
    end

    def valid?
      !name.nil? && !name.empty?
    end

    def meets_version?(app_version)
      return true if required_version.nil? || required_version.empty?
      
      begin
        Gem::Version.new(app_version) >= Gem::Version.new(required_version)
      rescue ArgumentError
        true # If version parsing fails, assume it's compatible
      end
    end
  end
end
