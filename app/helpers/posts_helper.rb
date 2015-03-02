module PostsHelper
	def checkAvatar(avatar)
		if avatar.url == '/images/user_icon.png'
			''
		else
			avatar.url(:medium)
		end
	end

	def has_access? 
		if params[:action] == 'account'
			params[:id].to_i == session[:userid]
		else 
			params[:user_id].to_i == session[:userid]
		end
	end

	def get_account_path
		if params['action'] == 'account' || params['action'] == 'tags' 
			return user_account_path(params[:id])
		end
			
		user_account_path(params[:user_id])
	end

	def check_requests
  		return 	Friendship.where('user_id = ? and accepted = false	 and sender <> user_id', session[:userid]).count
	end

	def is_friends? 
		user_id = params[:user_id].present? ? params[:user_id] : params[:id]
		friendship = Friendship.where('user_id = ? and friend_id = ? ', session[:userid], user_id)

		friendship.present? || user_id.to_i == session[:userid]
	end

	def show_requests?
		user_id = params[:controller] == 'posts' ? params[:user_id] : params[:id]
		
		session[:userid] == user_id.to_i 
	end

	def get_user post
		if @friends.present?
			index = @friends.index { |friend| friend.id == post.user_id }
			if index
				@friends[index]
			else
				@user
			end
		else
			User.find(post.user_id)
		end
	end

	def getTagMargins
		if params[:controller] == 'posts'
			'margin-left:10px'
		else
			''
		end
	end

	def getStylesheet
		if params[:action] == 'dashboard' || !@user.present?
			'/stylesheets/default.css'
		else
			if @user.theme.present?
				"/stylesheets/#{@user.theme}.css"
			else
				"/stylesheets/default.css"
			end
		end
	end
	
end
