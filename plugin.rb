enabled_site_setting :domain_locale_enabled

after_initialize do
  
  module ::DiscourseDomainLocale
    PLUGIN_NAME ||= "discourse-domain-locale".freeze
  end
  
  # Hook into ApplicationController to set locale before each request
  ApplicationController.class_eval do
    prepend_before_action :set_locale_by_domain
    
    private
    
    def set_locale_by_domain
      return unless SiteSetting.domain_locale_enabled
      
      domain = request.host
      locale = get_locale_for_domain(domain)
      
      if locale && I18n.available_locales.include?(locale.to_sym)
        # Set locale for this request
        I18n.locale = locale
        
        # For logged-out users, set a cookie so it persists
        unless current_user
          cookies[:locale] = {
            value: locale,
            expires: 1.year.from_now
          }
        end
      end
    end
    
    def get_locale_for_domain(domain)
      # Parse the domain_locale_mappings setting
      mappings = SiteSetting.domain_locale_mappings.split('|').map do |mapping|
        parts = mapping.split(':')
        [parts[0].strip, parts[1].strip] if parts.length == 2
      end.compact.to_h
      
      mappings[domain]
    end
  end
end