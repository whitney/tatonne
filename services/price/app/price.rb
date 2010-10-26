#class Price < Handler::Base
class Price

	def self.get(params)
		{:api => 'price'}.merge(params).to_json
	end

	def post(params)
	end

end
