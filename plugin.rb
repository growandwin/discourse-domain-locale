# name: discourse-domain-locale
# about: Automatically sets locale based on domain name
# version: 1.0.0
# authors: Jarek Growin
# url: https://github.com/growandwin/discourse-domain-locale

enabled_site_setting :domain_locale_enabled

after_initialize do
  
  add_model_callback(:application_controller, :before_action) do
    next unless SiteSetting.domain_locale_enabled
    
    domain = request.host
    mappings = SiteSetting.domain_locale_mappings.split('|').map do |mapping|
      parts = mapping.split(':')
      [parts[0].strip, parts[1].strip] if parts.length == 2
    end.compact.to_h
    
    locale = mappings[domain]
    
    if locale && I18n.available_locales.include?(locale.to_sym)
      I18n.locale = locale
      
      unless current_user
        cookies[:locale] = {
          value: locale,
          expires: 1.year.from_now
        }
      end
    end
  end
end