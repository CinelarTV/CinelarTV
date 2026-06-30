class EmailStyleUpdater
  attr_reader :errors

  def initialize(user)
    @user = user
    @errors = []
  end

  def update(attrs)
    if attrs.has_key?(:html) && !attrs[:html].include?("%{email_content}")
      @errors << "HTML template must contain the %{email_content} placeholder"
    end

    if attrs.has_key?(:css)
      begin
        compiled_css = compile_css(attrs[:css])
      rescue => e
        @errors << e.message
      end
    end

    return false unless @errors.empty?

    if attrs.has_key?(:html)
      if attrs[:html] == EmailStyle.default_template
        SiteSetting.find_by(var: 'email_custom_template')&.destroy
      else
        SiteSetting.email_custom_template = attrs[:html]
      end
    end

    if attrs.has_key?(:css)
      if attrs[:css] == EmailStyle.default_css
        SiteSetting.find_by(var: 'email_custom_css')&.destroy
        SiteSetting.find_by(var: 'email_custom_css_compiled')&.destroy
      else
        SiteSetting.email_custom_css = attrs[:css]
        SiteSetting.email_custom_css_compiled = compiled_css
      end
    end

    @errors.empty?
  end

  private

  def compile_css(css)
    return "" if css.blank?

    if defined?(SassC)
      SassC::Engine.new(css, style: :compressed).render
    else
      css
    end
  end
end
