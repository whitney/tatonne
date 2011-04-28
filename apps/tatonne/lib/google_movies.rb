require 'open-uri'
require 'nokogiri'

class GoogleMovies

	NYC           = "new+york,+ny,+usa"
	TODAY         = 0
	TOMORROW      = 1
	BASE_URI      = "http://www.google.com/movies?hl=en&near="
	NYC_URI       = "http://www.google.com/movies?hl=en&near=new+york,+ny,+usa&date=0"
	PORTLAND_URI  = "http://www.google.com/movies?hl=en&near=portland,+or,+usa&date=0"

	attr_accessor :html, :movies

	def initialize(uri=NYC_URI)

		self.movies = []
		self.html = "<ul>"

		doc = Nokogiri::HTML(open(uri))
		doc.xpath('//div[@class = "movie_results"]/div[@class = "theater"]').each do |node|
			theater = {:theater => {}, :movies => []}
			theater[:theater][:name] = node.xpath('.//div[@class = "desc"]/h2[@class = "name"]').text
			theater[:theater][:info] = node.xpath('.//div[@class = "desc"]//div[@class = "info"]').text
			theater[:theater][:location_info] = theater[:theater][:info][0, theater[:theater][:info].index("-") - 1].split(",")
			theater[:theater][:street_address] = theater[:theater][:location_info][0]
			theater[:theater][:city] = theater[:theater][:location_info][1]
			theater[:theater][:state] = theater[:theater][:location_info][2]
			theater[:theater][:phone] = theater[:theater][:info][theater[:theater][:info].index("-") + 2, 64]

			# cleanup
			theater[:theater][:name] = strip(theater[:theater][:name])
			theater[:theater][:street_address] = strip(theater[:theater][:street_address])
			theater[:theater][:city] = strip(theater[:theater][:city])
			theater[:theater][:state] = strip(theater[:theater][:state])
			theater[:theater][:phone] = strip(theater[:theater][:phone])

			# HTML:
			self.html += "<li><b>#{theater[:theater][:name]}</b> | #{theater[:theater][:info]}<br />"

			# next loop over the movies
			node.xpath('.//div[@class = "showtimes"]//div[@class = "movie"]').each do |node|
				theater[:movies] << node.xpath('.//div[@class = "name"]/a').text
				# HTML:
				self.html += "#{node.xpath('.//div[@class = "name"]/a').text} | "
				self.html += "#{node.xpath('.//div[@class = "times"]').text}<br />"
			end
			# HTML:
			self.html += "</li>"
			
			self.movies << theater
		end
		self.html += "</ul>"
	end	

	def strip(str)
		str ? str.strip : nil
	end

end
