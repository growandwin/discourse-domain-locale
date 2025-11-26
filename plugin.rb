# name: discourse-domain-locale
# about: Automatically sets locale based on domain name
# version: 1.0.0
# authors: Your Name
# url: https://github.com/yourusername/discourse-domain-locale

enabled_site_setting :domain_locale_enabled

after_initialize do
  
  # Add site settings for domain-to-locale mapping
  require_dependency 'application_controller'
  
  module ::DiscourseDomainLocale
    PLUGIN_NAME ||= "discourse-domain-locale".freeze
    
    class Engine < ::Rails::Engine
      engine_name PLUGIN_NAME
      isolate_namespace DiscourseDomainLocale
    end
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
        if !current_user
          cookies[:locale] = {
            value: locale,
            expires: 1.year.from_now,
            domain: :all
          }
        end
        
        # Optional: Update logged-in user's preference if different
        if current_user && current_user.locale != locale
          # Only update if user hasn't manually set a preference
          # You can add additional logic here if needed
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