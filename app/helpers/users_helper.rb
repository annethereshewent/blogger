module UsersHelper
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
end
