require 'rubygems'
require 'mechanize'

class FitocracyRuns
	def initialize
		@username = ""
		@userid = ""
		@userpic = ""
		@run_data = Hash.new
		@agent = Mechanize.new
		@agent.follow_meta_refresh = true
  		@agent.user_agent_alias = 'Windows Mozilla'
	end

	# Public methods

	def authenticate(un,pw)
		login_url = "https://www.fitocracy.com/accounts/login/?next=%2Flogin%2F"
		login_page = @agent.get(login_url) # check to make sure this returns a login page (it doesn't if Fitocracy is under maintence)

		login_form = login_page.form_with(:id => 'username-login-form')

		csrfmiddlewaretoken = login_form['csrfmiddlewaretoken']

		logged_in = @agent.post('https://www.fitocracy.com/accounts/login/', {
			"csrfmiddlewaretoken" => csrfmiddlewaretoken,
			"is_username" => "1",
			"json" => "1",
			"next" => "/home/",
			"username" => un,
			"password" => pw
			})

		home_page = @agent.get("https://www.fitocracy.com/home/")

		if validate_login(logged_in)
			@username = un
			@userpic = get_userpic(home_page)
			@userid = get_userid
			
			return true
		else
			return false
		end
	end

	def get_run_data
		stream_offset = 0
		stream_increment = 15

		user_stream_url = "http://www.fitocracy.com/activity_stream/" + stream_offset.to_s + "?user_id=" + @userid
		user_stream = @agent.get(user_stream_url)
		
		@run_data['username'] = @username
		@run_data['userid'] = @userid
		@run_data['userpic'] = @userpic
		@run_data['runs'] = []

		p @run_data
		begin
			items = user_stream.search("div.stream_item")
			items.each do|i|
				datetime = get_item_datetime(i)

				actions = i.search("ul.action_detail li")
				actions.each do |a|
					
				end

			end

			stream_offset += stream_increment
			user_stream_url = "http://www.fitocracy.com/activity_stream/" + stream_offset.to_s + "?user_id=" + @userid
			user_stream = @agent.get(user_stream_url)
		end while is_valid_stream(user_stream)
	end

	# Private methods

	def validate_login(logged_in_page)
		return true
	end
	
	def get_userid
	  	profile_pos = @userpic.index('profile/')
	  	end_pos = @userpic.index('/', profile_pos+8)

	  	return @userpic[profile_pos+8..end_pos-1]
	end

	# Pass in home page for best results
	def get_userpic(page)
		userpic_xpath = '(//a[@id="header_profile_pic"]/img/@src)[1]'
		pic_img = page.parser.xpath(userpic_xpath)

		return pic_img.text
	end

	def is_valid_stream(user_stream_page)
		return false
	end

	def get_item_datetime(item)
		return item.search("a.action_time").map{ |n| n.text }
	end

end
