module GCal
  class Authorization

    @@global_authorization  = nil
    @@token_update_callback = nil
    attr_reader :client, :service

    def initialize(token, refresh_token = nil)
      @client  = Google::APIClient.new
      @client.authorization.client_id     = GCal.google_client_id
      @client.authorization.client_secret = GCal.google_client_secret
      @client.authorization.scope         = 'https://www.googleapis.com/auth/calendar'
      @client.authorization.access_token  = token
      @client.authorization.refresh_token = refresh_token
      @service = @client.discovered_api('calendar', 'v3')
    end
    
    def valid?
      result = @client.execute api_method: @service.calendar_list.list
      return true if result.response.env[:status] == 200
      return false
    end
    alias_method :is_valid?, :valid?

    def update_token
      @client.authorization.fetch_access_token!
      
      # This should only happen if success, will throw an exception if not succesful
      token = @client.authorization.access_token
      @@token_update_callback.call(token) if @@token_update_callback.class.to_s == "Proc"
      
      token
    end

    def current_access_token
      self.update_token! unless self.is_valid?
      @client.authorization.access_token
    end

    def self.global
      @@global_authorization
    end

    def self.set_global_authorization(authorization)
      @@global_authorization = authorization
    end

    def self.token_update_callback=(val)
      @@token_update_callback = val
    end
  end
end