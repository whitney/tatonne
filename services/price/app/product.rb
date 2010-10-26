#class Product < Handler::Base
class Product

	def self.get(params)
		{:api => 'product'}.merge(params).to_json
	end

	def post(params)
	end

end
