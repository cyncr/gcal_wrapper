require "hashie"
require "google/api_client"

require "gcal_wrapper/version"
require "gcal_wrapper/authorization"
require "gcal_wrapper/calendar"

module GCal
  @@google_client_id     = nil
  @@google_client_secret = nil
  def self.google_client_id=(val);     @@google_client_id = val;     end
  def self.google_client_secret=(val); @@google_client_secret = val; end
  
  def self.google_client_id
    @@google_client_id     || ENV['GOOGLE_CLIENT_ID']     # || A yaml load ver
  end

  def self.google_client_secret
    @@google_client_secret || ENV['GOOGLE_CLIENT_SECRET'] # || A yaml load ver
  end

  class Base
    @@call_count = 0

    def self.api_call(api_method, params = {})
      # Check if valid method
      raise InvalidApiMethodString.new(api_method) unless valid_api_method? api_method
      api_methods = api_method.split('.')

      # Check if there is an authorization to run the call with
      authorization = params[:authorization] || Authorization.global
      raise NoAuthorizationError.new(self) if authorization.nil?

      # Prep the API parameters
      api_parameters = { 
        api_method: authorization.service.send(api_methods[0]).send(api_methods[1])
      }

      headers = params.has_key?(:headers) ?  params[:headers] : {}
      headers["Content-Type"] = "application/json"
      api_parameters[:headers]     = headers
      api_parameters[:parameters]  = params[:parameters] if params.has_key? :parameters
      api_parameters[:body_object] = params[:body]       if params.has_key? :body

      # Run the query against google
      response = authorization.client.execute api_parameters

      # Returned invalid auth response, try reruning it with an updated token
      if response.response.env[:status] == 401
        @@call_count = @@call_count + 1
        raise InvalidOauthAuthentication if @@call_count > 2

        authorization.update_token
        Base.api_call(api_method, params)
      else
        # Check for etag match
        return false if response.response.env[:status] == 304 # The Etag matched

        # Return the response if all valid
        response
      end
    end

    # Setup private class variables
    class << self

      private

      def valid_api_method?(method)
        valid = %w[
          acl.delete
          acl.get
          acl.insert
          acl.list
          acl.update
          acl.patch
          calendar_list.delete
          calendar_list.get
          calendar_list.insert
          calendar_list.list
          calendar_list.update
          calendar_list.patch
          calendars.clear
          calendars.delete
          calendars.get
          calendars.insert
          calendars.update
          calendars.patch
          colors.get
          events.delete
          events.get
          events.import
          events.insert
          events.instances
          events.list
          events.move
          events.quick_add
          events.update
          events.patch
          freebusy.query
          settings.get
          settings.list
        ]
        valid.include? method
      end
    end
  end

  class InvalidApiMethodString < StandardError
    def initialize(method)
      super "The #{method} is not a valid Google Calendar V3 API call."
    end
  end

  class NoAuthorizationError < StandardError
    def initialize(klass)
      super "An #{klass.class.to_s} was initialized without an authorization object passed in or one set to the global space."
    end
  end

  class GDataObjectNotFound < StandardError
    def initialize(api_method, parameters)
      parameters.has_key?(:parameters) ? p = parameters[:parameters].to_s : ""
      super "A Google API object could not be found for #{api_method} #{p}"
    end
  end

  class InvalidOauthAuthentication < StandardError
    def initialize
      super "The request responded with a 401 invalid authentication even after an attempt to fetch a new token."
    end
  end
end