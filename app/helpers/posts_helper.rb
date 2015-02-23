module PostsHelper
	def checkAvatar(avatar)
		if avatar.url == '/images/user_icon.png'
			return ''
		else
			return avatar.url(:medium)
		end
	end

	def print_tags(tags)
		if params[:action] == 'tags'
			return ''
		end
		returnStr = ""
		tags.each do |tag| 
			returnStr += "<span class='tags'><a href='/users/#{@user.id}/tags/#{tag.tag_name.gsub(' ', '-')}'>#{tag.tag_name}</a></span>" 
		end

		returnStr
	end
end
