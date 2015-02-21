class PostsController < ApplicationController
	def index
		@user = User.find(params[:user_id])
		@posts = @user.posts.order('id desc').first(15)
	end

	def create
		if @post = Post.create(post: params[:htmlContent], user_id: params[:user_id])
			redirect_to user_posts_path params[:user_id]
		else
			redirect_to user_posts_path params[:user_id], notice: "Could not save post"
		end
	end

	def delete
		if Post.destroy(params[:post_id])
			render plain: "success"
		else
			render plain: "false"
		end
	end

	def fetch 
		@post = Post.find(params[:post_id])
		if @post
			render plain: {
							:status  => true,
							:content => @post.post,
				  		}.to_json				
		else
			render plain: {
							:status => false
			  		  	}.to_json
		end
	end
end
