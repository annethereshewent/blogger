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

	def getPageFooter
		page = params[:page].present? ? params[:page].to_i : 1
		num_posts = @user.posts.page(page).per(20).count
		if num_posts > 15
			if page == 1
				
				'<span class="navi">
					<a class="pagi-link" href="/users/' + params[:user_id] + '/posts/' + page.to_i.next.to_s + '">Next Page</a>
				  </span>
				  <div style="margin-left:60px">Page ' + page + '</div>';
		  	else
		  	
  				  '<span class="navi">
					<a class="pagi-link" href="/users/' + params[:user_id] + '/posts/' + (page.to_i  - 1).to_s + '">Previous Page</a>
				  </span>
				  <span class="navi" style="margin-left:60px">
				  	<a class="pagi-link" href="/users/' + params[:user_id] + '/posts/' + page.to_i.next.to_s + '">Next Page</a>
				  </span>
				  <div style="margin-left:60px">Page ' + page + '</div>'
			end
		elsif page != 1
			'<span class="navi">
				<a class="pagi-link" href="/users/' + params[:user_id] + '/posts/' + (page.to_i  - 1).to_s + '">Previous Page</a>
			 </span>
			 <div style="margin-left:60px">Page ' + page + '</div'			 
		else
			'<div style="margin-left:60px">Page 1</div>'
		end
	end

	def has_access 
		if params[:action] == 'account'
			params[:id].to_i == session[:userid]
		else 
			params[:user_id].to_i == session[:userid]
		end
	end
end
