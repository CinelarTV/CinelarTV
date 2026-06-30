require "nokogiri"

module Email
  class Styles
    def initialize(html)
      @html = html
      @fragment = Nokogiri::HTML.fragment(html)
      @custom_styles = nil
    end

    def format_basic
      @fragment.css("img").each do |img|
        img["style"] = [img["style"], "max-width: 100%; height: auto;"].compact.join("; ")
      end
      self
    end

    def format_html
      style("body", "margin: 0; padding: 0; width: 100%;")
      style("a", "color: #0084F0; text-decoration: none;")
      style("h1, h2, h3, h4, h5, h6", "margin: 0 0 10px 0; font-weight: 600;")
      style("p", "margin: 0 0 10px 0;")
      style("blockquote", "border-left: 3px solid #ddd; padding-left: 10px; margin: 10px 0; color: #666;")
      format_custom
      self
    end

    def format_custom
      custom_styles.each do |selector, value|
        style(selector, value)
      end
      self
    end

    def style(selector, styles, attribs = {})
      @fragment.css(selector).each do |element|
        add_styles(element, styles) if styles
        attribs.each { |k, v| element[k] = v }
      end
    end

    def to_html
      @fragment.to_html
    end

    private

    def add_styles(node, new_styles)
      existing = node["style"]
      if existing.present?
        node["style"] = "#{new_styles}; #{existing}"
      else
        node["style"] = new_styles
      end
    end

    def custom_styles
      return @custom_styles unless @custom_styles.nil?

      css = EmailStyle.new.compiled_css
      @custom_styles = {}

      if css.present?
        require "css_parser" unless defined?(::CssParser::Parser)
        parser = ::CssParser::Parser.new(import: false)
        parser.load_string!(css)
        parser.each_selector do |selector, value|
          @custom_styles[selector] ||= +""
          @custom_styles[selector] << value
        end
      end

      @custom_styles
    end
  end
end
