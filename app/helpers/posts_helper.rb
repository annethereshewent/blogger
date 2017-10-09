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
			return user_account_path
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

	

	def getTagMargins
		if params[:controller] == 'posts'
			'margin-left:10px'
		else
			''
		end
	end

	def getStylesheet
		#if params[:action] == 'dashboard' || params[:action] == 'search' || params[:action] == 'archive' || !@user.present? || (params[:controller] == 'users' && params['action'] == 'tags')
		# if params[:action] != 'posts' || params[:action] != 'comments'
		puts "current controller: #{params[:controller]}" 
		if params[:controller] != 'posts' && params[:controller] != 'comments' && params[:action] != 'account'
			'/stylesheets/default.css'
		else
			if @user.theme.present?
				"/stylesheets/#{@user.theme.theme_name}.css"
			else
				"/stylesheets/default.css"
			end
		end
	end

	def getTagURL tag
		if params[:controller] == 'users'
			'/users/tags/' + tag.tag_name.gsub(' ', '-')
		else
			"/users/#{params[:user_id]}/tags/#{tag.tag_name.gsub(' ','-')}"
		end
	end
	
end
