require 'google_movies'

get '/' do
	if @user = current_user
		redirect '/movies'
	else
		redirect '/login'
	end
end

get '/login' do
  	erb :login
end

post '/login' do
	@user_session = UserSession.new(:email => params['email'], :password => params['password'])
	if @user_session.save
		redirect '/movies'
	else
		flash.now[:error] = "Login failed: #{@user_session.errors}."
		erb :login
	end
end

get '/logout' do
	current_user_session.destroy if current_user_session
	#flash[:notice] = "You've logged out."
	redirect '/login'
end

get '/signup' do
  	erb :signup
end

post '/signup' do
	@user = User.new(:email => params['email'], :password => params['password'], :first_name => params['first_name'], :last_name => params['last_name'])
	@user.password_confirmation = params['password_confirmation']
	if @user.save_without_session_maintenance
		# TODO: flash
		#notify "An activation email has been sent to #{params['email']}."
		@user.send_activation_email
		#redirect '/activation-sent'
		redirect '/login'
	else
		# TODO: flash
		#notify "Signup failed."
		redirect '/signup'
	end
end

get '/activate/:token' do
	if @user = User.find_by_perishable_token(params['token'])
		erb :activate
	else
		# TODO: flash
		#notify "Your activation link has expired. Please request another below"
		erb :resend_activation
	end
end

post '/activate' do
	if @user = User.find_by_email(params['email'])
		@user.active = true
		if @user.save
			@user_session = UserSession.new(:email => params['email'], :password => params['password'])
			if @user_session.save
				# TODO: flash
				#notify "Your account has been activated."
				redirect '/movies'
			else
				# TODO: flash
				#notify "Activation did not succeed."
				# TODO: this does not make sense
				redirect '/signup'
			end
		else
			# TODO: flash
			#notify "Activation did not succeed."
			# TODO: this does not make sense
			redirect '/signup'
		end
	else
		# TODO: flash
		#notify "Your activation link has expired. Please request another below"
		erb :resend_activation
	end
end

get '/resend-activation' do
	erb :resend_activation
end

post '/resend-activation' do
	if @user = User.find(:first, :conditions => {:email => params['email']})
		@user.send_activation_email
		# TODO: flash
		#notify "You should see an email for activating your account soon."
		redirect '/login'
	else
		# TODO: flash
		#notify "No account with email #{params[:email]} was found in our records. Make sure the email is correct."
		erb :resend_activation
	end
end

##################
# PASSWORD ADMIN #
##################
get '/forgot-password' do
	erb :forgot_password
end

post '/forgot-password' do
	if @user = User.find(:first, :conditions => {:email => params[:email]})
		@user.send_password_reset_email()
		flash[:notice] = "The email to reset your password has been sent to #{@user.email}."
		redirect '/login'
	else
		# TODO:
		# notify: No account with email #{params[:email]} exists in our records.
		erb :forgot_password
	end
end

get '/reset-password/:token' do
	if @user = User.find_by_perishable_token(params[:token])
		@token = params[:token]
		erb :reset_password
	else
		# notify: Your passord request link has expired. Please request another.
		redirect '/forgot-password'
	end
end

post'/reset-password' do
	if @user = User.find_by_email(params['email'])
		@user.password = params[:new_password]
		@user.password_confirmation = params[:new_password_confirmation]
		@user_session = UserSession.new(:email => params['email'], :password => params[:new_password])
		if @user.save and @user_session.save
			# TODO: flash
			#notify "Your password has been reset."
			redirect '/movies'
		else
			# TODO: flash
			#notify "Password reset did not succeed."
			redirect "/reset-password/#{params[:token]}"
		end
	else
		# notify: "Your password reset link has expired. Please request another."
		redirect '/forgot-password'
	end
end

get '/change-password' do
	@user = current_user
	erb :change_password
end

post'/change-password' do
	if @user = User.find_by_email(params['email'])
		@user.password = params[:new_password]
		@user.password_confirmation = params[:new_password_confirmation]
		if @user.save
			# TODO: flash
			#notify "Your password has been changed."
			redirect '/movies'
		else
			# TODO: flash
			#notify "Password change did not succeed."
			redirect '/change-password'
		end
	else
		# TODO: redirect to forgot-password
	end
end
