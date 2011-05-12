require File.dirname(__FILE__) + '/paypal_payment_details_response'
module ActiveMerchant
  module Billing
    module PaypalAdaptiveCommon
      
      SUCCESS_CODES = [ 'Success', 'SuccessWithWarning' ]
      
      def self.included(base)
        base.cattr_accessor :test_url
        base.cattr_accessor :live_url
      end
      
      private
      
      def endpoint_url
        test? ? test_url : live_url
      end
      
      def build_url(action)
        "#{endpoint_url}/#{action}"
      end
      
      def build_request(action, body)
        xml = Builder::XmlMarkup.new
        xml.instruct!
        xml.tag! "#{action}Request" do
          xml.tag! 'requestEnvelope' do
            xml.tag! 'detailLevel', 'ReturnAll'
          end
          xml << body
        end
        xml.target!
      end
      
      def successful?(response)
        SUCCESS_CODES.include?(response[:ack])
      end
      
      def message_from(response)
        response[:message] || response[:status] || response[:payment_exec_status] || response[:ack]
      end
      
      def build_response(action, success, message, response, options = {})
         case action
         when 'PaymentDetails'
           PaypalPaymentDetailsResponse.new(success, message, response, options)
         else
           Response.new(success, message, response, options)
         end
      end
     
      def parse(action, json)
        result = ActiveSupport::JSON.decode(json)
        response = {}
        result.each do |k,v|
          response[k.underscore.to_sym] = v if v.is_a?(String)
        end
        if result['responseEnvelope']
          result['responseEnvelope'].each do |k,v|
            response[k.underscore.to_sym] = v if v.is_a?(String)
          end
        end
        if result['paymentInfoList']
          response[:payment_list] = result['paymentInfoList']['paymentInfo']
        end
        if result['error']
          response[:message] = result['error'].collect{|e| e['message'] }.uniq.join('. ')
          response[:error_codes] = result['error'].collect{|e| e['errorId'] }.uniq.join(', ')
        end
        response
      end     
      
    end
  end
end