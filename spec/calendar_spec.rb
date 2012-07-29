require 'gcal_wrapper'

describe "GCal::Calendar" do
  before :each do
    GCal.google_client_id     = '126393085427.apps.googleusercontent.com'
    GCal.google_client_secret = 'Xb84ko4waCC4a1J0LS0RRNi2'

    @auth = GCal::Authorization.new(
      'ya29.AHES6ZQ3W3Xfa42clqqwBxqHHfZ4TYtpO6c7J-rpRKGKvl5MeL9T-w',
      '1/l3tkvw4ooktbHTnXI_943aBrpomic88C9-HhhlKvfGw')
  end

  it "should fail without any form of authorization" do
    lambda { GCal::Calendar.new({}) }.should
        raise_error(GCal::NoAuthorizationError)
  end

  it "should be able to initalized with the global authorization" do
    authorization = double "authorization"
    GCal::Authorization.set_global_authorization authorization
    GCal::Calendar.new({}).should be_kind_of GCal::Calendar
    # Reset global space after test is run
    GCal::Authorization.set_global_authorization nil
  end

  it "should be able to find a calendar from an id" do
    cal = GCal::Calendar.find('testsuite@cyncr.com', @auth)
    cal.description.should == "foobar"
  end

  describe "should be able to be initialized from an empty hash" do
    before :each do
      @cal = GCal::Calendar.new({}, @auth)
    end

    after :each do
      @cal.delete unless @cal.id.nil? # Ceanup
    end

    it "and respond to it's attributes" do
      @cal.should respond_to :id, :kind, :etag, :description, :location, :summary, 
        :selected, :time_zone, :color_id,  :access_role,  :default_reminders
    end

    it "and be able to save itself" do
      @cal.title = "foobar"
      @cal.save

      @cal.id.should_not   be_nil
      @cal.etag.should_not be_nil

      check = GCal::Calendar.find(@cal.id, @auth)
      check.title.should == "foobar"
    end

    it "and it should be able to delete itself" do
      @cal.title = "foobar"
      @cal.save
      @cal.id.should_not be_nil
      old_id = @cal.id

      @cal.delete
      @cal.id.should be_nil

      GCal::Calendar.find(old_id, @auth).should be_nil
    end

    it "and is should be able to check its etag for a change" do
      puts '*' * 88
      puts "Calendar ETag before save: #{@cal.etag}"
      @cal.title = "foobar"
      @cal.save
      puts "Calendar ETag after save: #{@cal.etag}"

      @cal2 = GCal::Calendar.find(@cal.id, @auth)
      puts "Calendar lookup after save: #{@cal2.etag}"

      @cal3 = GCal::Calendar.find(@cal.id, @auth)
      puts "Calendar second lookup after save: #{@cal3.etag}"


      @cal.id.should_not be_nil
      old_etag = @cal.etag

      @cal.title = "foobaz"
      @cal.save

      @cal4 = GCal::Calendar.find(@cal.id, @auth)
      puts "Calendar third lookup after save: #{@cal4.etag}"

      @cal5 = GCal::Calendar.find(@cal.id, @auth)
      puts "Calendar fourth lookup after save: #{@cal5.etag}"

      @cal6 = GCal::Calendar.find(@cal.id, @auth)
      puts "Calendar fifth lookup after save: #{@cal6.etag}"
      @cal.etag.should_not == old_etag

      @cal.changed?(old_etag)
      @cal.changed?(@cal.etag)
      #@cal.changed?(old_etag).should be_kind_of GCal::Calendar
      #@cal.changed?(@cal.etag).should == false
    end
  end
end