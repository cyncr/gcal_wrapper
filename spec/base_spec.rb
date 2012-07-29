require 'gcal_wrapper'

describe "GCal::Base" do
  before :each do
    GCal.google_client_id     = '126393085427.apps.googleusercontent.com'
    GCal.google_client_secret = 'Xb84ko4waCC4a1J0LS0RRNi2'

    @auth = GCal::Authorization.new(
      'ya29.AHES6ZQ3W3Xfa42clqqwBxqHHfZ4TYtpO6c7J-rpRKGKvl5MeL9T-w',
      '1/l3tkvw4ooktbHTnXI_943aBrpomic88C9-HhhlKvfGw')
    @params = { authorization: @auth }
  end

  it "should raise an exception if an invalid api call is requested" do
    lambda { GCal::Base.api_call 'foo.bar' }.should raise_error
  end

  it "should return a list of calendars" do
    #VCR.use_cassette('base/calendars.list') do
      response = GCal::Base.api_call 'calendar_list.list', @params
      response.response.env[:status].should == 200
      response.data.items.first.class.to_s.should == "Google::APIClient::Schema::Calendar::V3::CalendarListEntry"
    #end
  end

  describe "should be able to create a new calendar" do
    before :each do
      body = { 
        'description' => Faker::Lorem.sentence(3),
        'location'    => Faker::Lorem.sentence(2),
        'summary'     => Faker::Lorem.sentence(3),
        'timeZone'    => 'America/Los_Angeles'
      }
      @params[:body] = body

      #VCR.use_cassette('base/calendars.insert') do
        @response = GCal::Base.api_call 'calendars.insert', @params
      #end

      @status = @response.response.env[:status]
      @body   = JSON.parse(@response.response.env[:body])
      @id     = @body["id"]
    end

    it "and be succesful" do
      @status.should == 200
    end

    it "and delete it" do
      #VCR.use_cassette('base/calendars.delete') do
        delete_response = GCal::Base.api_call 'calendars.delete', 
                              parameters: { 'calendarId' => @id },
                              authorization: @auth
      #end
      delete_response.response.env[:status].should == 204 # No Content
    end

    it "and update it" do
      @body['description'] = "foobar"
      update_response = GCal::Base.api_call 'calendars.update',
                            parameters: { 'calendarId' => @id },
                            authorization: @auth,
                            body: @body
      update_response.response.env[:status].should == 200
      update_body = JSON.parse(update_response.response.env[:body])
      update_body['description'].should == "foobar"
    end
  end
end
