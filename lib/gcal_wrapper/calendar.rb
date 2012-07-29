module GCal
  class Calendar < Hashie::Trash
    attr_reader :authorization

    property :id 
    property :kind
    property :etag
    property :description
    property :location
    property :summary
    property :selected
    property :time_zone,         from: :timeZone
    property :color_id,          from: :colorId
    property :access_role,       from: :accessRole
    property :default_reminders, from: :defaultReminders

    alias_method :title,  :summary
    alias_method :title=, :summary=

    def initialize(hash, authorization = nil)
      super hash
      yield self if block_given?
      
      @authorization = authorization || Authorization.global
      raise NoAuthorizationError.new(self) if @authorization.nil?
    end

    def self.find(calendar_id, authorization = nil)
      response = Base.api_call 'calendars.get', 
                    authorization: authorization,
                    parameters: { 'calendarId' => calendar_id }

      return nil unless response.response.env[:status] == 200
      
      body = JSON.parse(response.response.env[:body])
      Calendar.new(body, authorization)
    end

    def self.all
      Authorization.global.update_token! unless Authorization.global.is_valid?
      response = Authorization.global.client.execute api_method: Authorization.global.service.calendar_list.list
      results = JSON.parse response.response.env[:body]

      # TODO: Create a CalendarList object to store the etag info
      results['items'].map {|calendar| Calendar.new(calendar, Authorization.global) }
    end

    # Maps to Calendar#delete
    # Need to implement calendar#clear for primary calendar
    def delete
      response = Base.api_call 'calendars.delete', 
                    authorization: authorization,
                    parameters: { 'calendarId' => self.id }
      # result = client.execute api_method: service.calendars.clear,
      #                           parameters: { 'calendarId' => @id }

      # returns result.response.env[:status] == 204 if succesfully
      self.id = nil
      self.etag = nil
      self
    end

    def save
      @id.nil? ? create_calendar : update_calendar
    end

    def events
      parameters = {
        'calendarId' => @id,
        'singleEvents' => 'True',
        'timeMin' => Time.now.getutc.strftime("%FT%T.%LZ"),
        'orderBy' => 'startTime'
        
      }
      response = client.execute api_method: service.events.list,
                                parameters: parameters
      response.data.items.map {|event| Event.new event }
    end

    def changed?(etag = nil)
      etag = etag || self.etag

      response = Base.api_call 'calendars.get', 
                                authorization: @authorization,
                                headers: { 'If-None-Match' => etag },
                                parameters: { 'calendarId' => self.id }

      # Check the etag response for a change
      return false if response.response.env[:status] == 304
      
      # If there is a change, return the response
      body = JSON.parse(response.response.env[:body])
      Calendar.new(body, authorization)
    end

    def self.changed?(calendar_id, etag, authorization = nil)
      calendar = Base.api_call 'calendars.get', authorization: authorization,
                    parameters: { 'calendarId' => calendar_id },
                    headers: { 'If-None-Match' => etag }
    end

    private

    def create_calendar
      insert = { 
        'description' => self.description,
        'location'    => self.location,
        'summary'     => self.summary,
        'timeZone'    => self.time_zone
      }

      response = Base.api_call 'calendars.insert', 
                    authorization: authorization,
                    body: insert

      body  = JSON.parse(response.response.env[:body])
      self.id   = body['id']   if body.has_key? "id"
      self.etag = body['etag'] if body.has_key? "etag"
      
      self
    end

    def update_calendar
      updates = { 
        'description' => @description,
        'location'    => @location,
        'summary'     => @summary,
        'timeZone'    => @time_zone
      }

      result = client.execute api_method: service.calendars.update,
                              parameters: { 'calendarId' => @id },
                              body_object: updates
      self
    end

    def client
      @authorization.client
    end

    def service
      @authorization.service
    end
  end
end