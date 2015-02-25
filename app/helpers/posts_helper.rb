module PostsHelper
	def checkAvatar(avatar)
		if avatar.url == '/images/user_icon.png'
			return ''
		else
			return avatar.url(:medium)
		end
	end

	def has_access 
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
	
end
