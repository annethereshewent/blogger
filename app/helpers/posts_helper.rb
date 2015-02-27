module PostsHelper
	def checkAvatar(avatar)
		if avatar.url == '/images/user_icon.png'
			return ''
		else
			return avatar.url(:medium)
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
  		return 	Friendship.where('user_id = ? and accepted = ? and sender <> user_id', session[:userid], false).count
	end

	def is_friends? 
		user_id = params[:user_id].present? ? params[:user_id] : params[:id]
		friendship = Friendship.where('user_id = ? and friend_id = ? ', session[:userid], user_id)

		friendship.present? || user_id.to_i == session[:userid]
	end

	def get_user post
		index = @friends.index { |friend| friend.id == post.user_id }
		if index.present?
			@friends[index]
		else
			@user
		end
	end

	def getTagMargins
		puts "DEBUG: #{params[:controller]}"
		if params[:controller] == 'posts'
			'margin-left:10px'
		else
			''
		end
	end
	
end
