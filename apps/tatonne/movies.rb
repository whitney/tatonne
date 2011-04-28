require 'google_movies'

get '/movies' do
	@user = current_user

	@location = params[:location] || session["location"]
	case @location
	when 'portland:OR'
		google_movies = GoogleMovies.new(GoogleMovies::PORTLAND_URI)
		@location = 'portland:OR'
		@coord = {:lat => 45.525, :lng => -122.67}
	else
		google_movies = GoogleMovies.new()
		@location = 'newyork:NY'
		@coord = {:lat => 40.736, :lng => -73.990}
	end

	@movies = google_movies.html
	session["location"] = @location
	erb :movies, :layout => :'layouts/movies'
end

# TODO: move to API
get '/movie-theaters' do
	require 'movie_theater'
	require 'movie_theater_location'

	@location = params[:location]
	case @location
	when 'portland:OR'
		# TODO: this will not work as there are more cities in a single state
		theater_locs = MovieTheaterLocation.find(:all, :conditions => ["state = 'OR'"])
		@location = 'portland:OR'
		@coord = {:lat => 45.525, :lng => -122.67}
	else
		# TODO: this will not work as there are more cities in a single state
		theater_locs = MovieTheaterLocation.find(:all, :conditions => ["state = 'NY'"])
		@location = 'newyork:NY'
		@coord = {:lat => 40.736, :lng => -73.990}
	end

	@theaters = []
	theater_locs.each_with_index { |loc, i|
		theater = loc.movie_theater
		@theaters << [theater.name, loc.latitude, loc.longitude, i+1]
	}
	@theaters.to_json
end


# TODO: move to sync-scripts dir
get '/movie-theaters/sync' do
	require 'movie_theater'
	require 'movie_theater_location'

	# grab movies/theaters
	nyc_movies = GoogleMovies.new().movies
	prtld_movies = GoogleMovies.new(GoogleMovies::PORTLAND_URI).movies

	# jam into db
	puts ">>> nyc movies:"
	nyc_movies.each do |mov|
		theater = mov[:theater]
		phone   = theater[:phone]
		movies  = theater[:movies]
		# create movie-theater
		mov_theater = MovieTheater.new(:name => theater[:name])
		mov_theater.save!
		puts ">>> theater: #{mov_theater.inspect}"
		# create movie-theater location
		address = MovieTheaterLocation.new(:movie_theater_id => mov_theater.id, :address_1 => theater[:street_address], :city => theater[:city], :state => theater[:state])
		address.save!
		puts ">>> address: #{address.inspect}"
	end

	puts ">>> portland movies:"
	prtld_movies.each do |mov|
		theater = mov[:theater]
		phone   = theater[:phone]
		movies  = theater[:movies]
		# create movie-theater
		mov_theater = MovieTheater.new(:name => theater[:name])
		mov_theater.save!
		puts ">>> theater: #{mov_theater.inspect}"
		# create movie-theater location
		address = MovieTheaterLocation.new(:movie_theater_id => mov_theater.id, :address_1 => theater[:street_address], :city => theater[:city], :state => theater[:state])
		address.save!
		puts ">>> address: #{address.inspect}"
	end

	redirect '/movies'
end

# TODO: move to sync-scripts dir
get '/movie-theaters/geocode' do
	require 'movie_theater_location'

	GOOGLE_GEOLOC_URL = "http://maps.googleapis.com/maps/api/geocode/json"

	addresses = MovieTheaterLocation.find(:all, :conditions => ["postal_code IS NULL OR latitude IS NULL OR longitude IS NULL"])
	#addresses.each {|a| puts ">>> address: #{a.inspect}"}
	
	# make geocoding reqs and update lat/long coord fields
	EventMachine.run {

		addresses.each do |address|
			# Google geocoding API breaks if reqs are made too rapidly
			sleep(0.5)

			street = address.address_1.gsub(" ", "+")
			city = address.city.gsub(" ", "+")
			state = address.state.gsub(" ", "+")

			url = "#{GOOGLE_GEOLOC_URL}?address=#{street},#{city},#{state}&sensor=false"

			http = EventMachine::HttpRequest.new(url).get

			http.callback {
				resp_map = JSON.parse(http.response)
				#puts ">>> http.response: #{resp_map}"

				results   = resp_map['results'][0]
				next if results.nil?

				postal_code = results['address_components'].find {|c| c['types'].include?('postal_code')}['long_name']

				geometry  = results['geometry']
				lat       = geometry['location']['lat']
				lng       = geometry['location']['lng']
				puts ">>> address id #{address.id}: postal-code --> #{postal_code}, lat --> #{lat}, lng --> #{lng}"

				address.postal_code  = postal_code
				address.latitude     = lat
				address.longitude    = lng
				address.save!
				EventMachine.stop
			}
		end

	}
	
	redirect '/movies'
end

