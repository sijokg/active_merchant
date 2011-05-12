require File.dirname(__FILE__) + '/paypal_adaptive/paypal_adaptive_common'
module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    class PaypalAdaptiveAccountGateway < Gateway
      
      include PaypalAdaptiveCommon
      
  
      self.test_url = 'https://svcs.sandbox.paypal.com/AdaptiveAccounts'
      self.live_url = 'https://svcs.paypal.com/AdaptiveAccounts'
      
      class_inheritable_accessor :default_country_code, :device_ip
      
      ACCOUNT_TYPES = [ 'Personal', 'Premier','Business' ]
      
      CURRENCY_CODES = [ 'AUD', 'CAD', 'CZK', 'DKK', 'EUR', 'HKD', 'HUF', 'ILS', 'JPY', 'NZD', 'PLN', 'GBP', 'CHF', 'USD']
      
      self.default_country_code = 'US'
      
      # The countries the gateway supports merchants from as 2 digit ISO country codes
      #self.supported_countries = ['AR','AU','AT','BR','CA','CN','CZ','DK','FR','DE','IL','IT','JP','MY','MX','NL','NZ','RU','ES','CH','SE','GB','US']
      
      # The card types supported by the payment gateway
      self.supported_cardtypes = [:visa, :master, :american_express, :discover, :maestro, :solo, :carte_aurore, :carte_bleue, :cofinoga, :carte_aura, :tarjeta_aurora, :jcb, :etoiles]
      
      # The homepage URL of the gateway
      self.homepage_url = 'http://x.com/'
      
      # The name of the gateway
      self.display_name = 'Paypal Adaptive Accounts'
      
      self.default_currency = 'USD'
      
      def initialize(options = {})
        requires!(options, :login, :password)
        @options = options
        super
      end  
      
      def account_create(options)
        commit('CreateAccount', build_account_create_request(options))
      end
      
      def get_verified_status(options)
        commit('GetVerifiedStatus', build_get_verified_status_request(options))
      end
      
      private
      
      def headers
       options =  {
          "X-PAYPAL-REQUEST-DATA-FORMAT" => "XML",
          "X-PAYPAL-RESPONSE-DATA-FORMAT" => "JSON",
          "X-PAYPAL-SECURITY-USERID" => @options[:login],
          "X-PAYPAL-SECURITY-PASSWORD" => @options[:password],
          "X-PAYPAL-SECURITY-SIGNATURE" => @options[:signature],
          "X-PAYPAL-APPLICATION-ID" => @options[:appl_id],
          "X-PAYPAL-DEVICE-IPADDRESS" => self.device_ip
        }
        options.merge!("X-PAYPAL-SANDBOX-EMAIL-ADDRESS" => @options[:x_paypal_sandbox_email]) if test?
        options
      end
      
      def build_account_create_request(options)
        default_options = options
        requires!(default_options, :account_type, :address, :citizenship_country_code, :contact_phone, :account_web_options, :currency, :date_of_birth, :name, :preferred_language_code, :remote_ip)
        self.device_ip = default_options[:remote_ip]
        requires!(default_options, :business_info) if default_options[:account_type] == 'Business'
        currency = get_currency(default_options) || default_currency
        country_code = default_options[:citizenship_country_code] || default_country_code
        post_data = ''
        xml = Builder::XmlMarkup.new :target => post_data, :indent => 2
        add_account_type(xml, default_options) unless default_options[:account_type].blank?
        xml.currencyCode currency
        xml.address do
          add_address(xml, default_options[:address])  
        end
        xml.citizenshipCountryCode country_code
        xml.contactPhoneNumber default_options[:contact_phone]
        xml.emailAddress default_options[:email_address]
        xml.registrationType default_options[:registration_type] unless default_options[:registration_type].blank?
        add_account_web_options(xml, default_options[:account_web_options])
        xml.dateOfBirth default_options[:date_of_birth]
        add_name(xml, default_options[:name])
        xml.preferredLanguageCode default_options[:preferred_language_code]
        add_business_info(xml, default_options[:business_info]) if default_options[:account_type] == 'Business'
        xml.notificationURL default_options[:notification_url] unless default_options[:notification_url].blank? 
        post_data
      end
      
      def build_get_verified_status_request(options)
        default_options = options
        requires!(default_options, :first_name, :last_name, :email_address, :remote_ip)
        self.device_ip = default_options[:remote_ip]
        post_data = ''
        xml = Builder::XmlMarkup.new :target => post_data, :indent => 2
        xml.firstName default_options[:first_name]
        xml.lastName default_options[:last_name]
        xml.emailAddress default_options[:email_address]
        xml.matchCriteria 'NAME'
        post_data
      end
      
      def add_account_type(xml, options)
        if options[:account_type] && ACCOUNT_TYPES.include?(options[:account_type].to_s)
          xml.accountType options[:account_type]
        end        
      end
      
      def get_currency(options)
        if options[:currency] && CURRENCY_CODES.include?(options[:currency].to_s)
          options[:currency]
        end
      end
      
      def add_address(xml, options)
        requires!(options, :line1, :city, :country_code, :state, :postal_code)
        xml.line1 options[:line1]
        xml.city options[:city]
        xml.countryCode options[:country_code]
        xml.line2 options[:line2] unless options[:line2].blank?
        xml.state options[:state]
        xml.postalCode options[:postal_code]
      end
      
      def add_account_web_options(xml, options)
        requires!(options, :return_url)
        xml.createAccountWebOptions do
          xml.returnUrl options[:return_url]
          xml.returnUrlDescription options[:return_url_description] unless options[:return_url_description].blank?
          xml.showAddCreditCard options[:show_add_creditCard] unless options[:show_add_creditCard].blank?
        end
      end
      
      def add_name(xml, options)
        requires!(options, :first_name, :last_name)
        xml.name do
          xml.firstName options[:first_name]
          xml.lastName options[:last_name]
          xml.salutation options[:salutation] unless options[:salutation].blank?
          xml.middleName options[:middle_name] unless options[:middle_name].blank?
          xml.suffix options[:suffix] unless options[:suffix].blank?
        end
      end
      
      def add_business_info(xml, options)
        xml.businessInfo do
          requires!(options, :business_address, :business_name, :work_phone, :category, :sub_category, 
                             :customer_service_phone, :customer_service_email, :date_of_establishment, 
                             :business_type, :average_price, :average_monthly_volume, :percentage_revenue_from_online, 
                             :sales_venue, :web_site)
          xml.businessAddress do
           add_address(xml,options[:business_address])
          end
          xml.businessName options[:business_name]
          xml.workPhone options[:work_phone]
          xml.category options[:category]
          xml.subCategory options[:sub_category]
          xml.customerServicePhone options[:customer_service_phone]
          xml.customerServiceEmail options[:customer_service_email]
          xml.dateOfEstablishment options[:date_of_establishment]
          xml.businessType options[:business_type]
          xml.averagePrice options[:average_price]
          xml.averageMonthlyVolume options[:average_monthly_volume]
          xml.percentageRevenueFromOnline options[:percentage_revenue_from_online]
          xml.salesVenue options[:sales_venue]
          xml.webSite options[:web_site]
        end
      end
      
      def commit(action, request)
        response = parse(action, ssl_post(build_url(action), build_request(action,request), headers))
        build_response(action, successful?(response), message_from(response), response, 
          :test => test?
        )
      end

    end
  end
end

