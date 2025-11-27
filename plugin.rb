# name: discourse-domain-locale
# about: Automatically sets locale based on domain name
# version: 1.0.0
# authors: Jarek Growin
# url: https://github.com/growandwin/discourse-domain-locale

enabled_site_setting :domain_locale_enabled

after_initialize do
  
  # Hook do set_locale_from_accept_language PRZED innymi
  ApplicationController.class_eval do
    prepend_before_action :set_locale_by_domain_plugin, prepend: true
    
    def set_locale_by_domain_plugin
      return unless SiteSetting.domain_locale_enabled
      
      domain = request.host
      mappings = SiteSetting.domain_locale_mappings.split('|').map do |mapping|
        parts = mapping.split(':')
        [parts[0].strip, parts[1].strip] if parts.length == 2
      end.compact.to_h
      
      locale = mappings[domain]
      
      if locale && I18n.available_locales.include?(locale.to_sym)
        # Ustaw PRZED jakimkolwiek renderowaniem
        I18n.locale = locale
        
        # Dla niezalogowanych - ustaw cookie
        unless current_user
          cookies[:locale] = locale
        end
        
        # KRYTYCZNE: Ustaw też w request.env dla innych middleware
        request.env['HTTP_ACCEPT_LANGUAGE'] = locale
      end
    end
  end
end