module PostsHelper
	def checkAvatar avatar
		if avatar.url == '/images/user_icon.png'
			return ''
		else
			return avatar.url(:medium)
		end
	end
end
