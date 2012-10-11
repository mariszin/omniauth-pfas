require "time"
require "rexml/document"
require "rexml/xpath"
require "openssl"
require "xmlcanonicalizer"
require "digest/sha1"

require "omniauth/strategies/pfas/response"
require "omniauth/strategies/pfas/signed_document"

module OmniAuth
  module Strategies
    #
    # Authenticate with PFAS Auth
    #
    # @example Basic Rails Usage
    #
    #  Add this to config/initializers/omniauth.rb
    #
    #    Rails.application.config.middleware.use OmniAuth::Builder do
    #      provider :pfas, {
    #        :endpoint => "https://epaktv.vraa.gov.lv/IVIS.Pfas.STS/Default.aspx",
    #        :certificate => File.read("/path/to/cert"),
    #        :realm => "http://www.example.com"
    #      }
    #    end
    #
    class Pfas
      include OmniAuth::Strategy

      class ValidationError < StandardError; end

      def request_phase
        params = {
          :wa => 'wsignin1.0',
          :wct => Time.now.utc.strftime('%Y-%m-%dT%H:%M:%SZ'),
          :wtrealm => @options[:realm],
          :wreply => callback_url,
          :wctx => callback_url,
          :wreq => '<wst:RequestSecurityToken xmlns:wst="http://docs.oasis-open.org/ws-sx/ws-trust/200512" xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd"><wst:Claims xmlns:i="http://schemas.xmlsoap.org/ws/2005/05/identity" Dialect="http://schemas.xmlsoap.org/ws/2005/05/identity"><i:ClaimType Uri="http://docs.oasis-open.org/wsfed/authorization/200706/claims/action" Optional="false" /><i:ClaimType Uri="http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname" Optional="false" /><i:ClaimType Uri="http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname" Optional="false" /></wst:Claims><wst:RequestType>http://docs.oasis-open.org/ws-sx/ws-trust/200512/Issue</wst:RequestType><wst:Renewing /></wst:RequestSecurityToken>'
        }
        query_string = params.collect{ |key, value| "#{key}=#{Rack::Utils.escape(value)}" }.join('&')
        redirect "#{options[:endpoint]}?#{query_string}"
      end

      def callback_phase
        if request.params['wresult']
          @response = OmniAuth::Strategies::Pfas::Response.new(request.params['wresult'], {
            :certificate => File.read(options[:certificate])
          })
          @response.validate!
          super
        else
          fail!(:invalid_response)
        end
      rescue Exception => e
        fail!(:invalid_response, e)
      end

      def auth_hash
        OmniAuth::Utils.deep_merge(super, {
          'uid' => "#{@response.attributes['primarysid']}",
          'user_info' => {
            'user_name' => "#{@response.attributes['name']}",
            'privatepersonalidentifier' => "#{@response.attributes['privatepersonalidentifier']}",
            'authority' => @response.attributes['AUTHORITY'],
            'email' => "#{@response.attributes['emailaddress']}",
            'givenname' => "#{@response.attributes['givenname']}",
            'surname' => "#{@response.attributes['surname']}",
            'roles' => @response.attributes['action']
          },
          'expires_on' => @response.expires_on
        })
      end
    end
  end
end
