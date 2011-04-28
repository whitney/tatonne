class UserSession < Authlogic::Session::Base
end

class User < ActiveRecord::Base
	has_and_belongs_to_many :roles

	acts_as_authentic do |c|
		# put some auth stuffs here
	end

	def active?
		active
	end

	def has_no_credentials?
		crypted_password.blank? # && self.openid_identifier.blank?
	end

	def send_activation_email
		Pony.mail(
			:to => self.email,
			:from => "no-reply@tatonne.com",
			:subject => "Activate your account",
			:body => "Thank you for signing up!\n\n" +
				 "To activate your account use the following link: " + 
				 "http://tatonne.com/activate/#{self.perishable_token}"
		)
	end

	def send_password_reset_email
		Pony.mail(
			:to => self.email,
			:from => "no-reply@tatonne.com",
			:subject => "Reset your password",
			:body => "We have recieved a request to reset your password.\n\n" +
				 "If you did not send this request, then please ignore this email.\n\n" + 
				 "If you did send the request, you may reset your password using the following link: " + 
				 "http://tatonne.com/reset-password/#{self.perishable_token}"
		)
	end
end
