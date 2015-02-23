class PostsController < ApplicationController
	def index
		@user = User.find(params[:user_id])
		@posts = @user.posts.order('id desc').first(15)
	end

	def create
		if @post = Post.create(post: params[:htmlContent], user_id: params[:user_id])
			params[:tags].split(',').each do |tag|
				if (@tag = Tag.where('tag_name = ? ', tag)).present? 	
					PostTag.create(tag_id: @tag[0].id, post_id: @post.id)
				else
					@tag = Tag.create(tag_name: tag)
					PostTag.create(tag_id: @tag.id, post_id: @post.id)
				end
			end
			redirect_to user_posts_path params[:user_id]
		else
			flash[:notice] = "Could not save post"
			redirect_to user_posts_path params[:user_id]
		end
	end
	def update
		if Post.update(params[:id], post: params[:htmlContent], edited: 1)
			redirect_to user_posts_path params[:user_id]
		else
			flash[:notice] = "Unable to update post"
			redirect_to user_posts_path params[:user_id]
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

	def tags 
		@user = User.find(params[:id])
		params[:tag].gsub!('-', ' ')
		@posts = @user.posts.where(
			'id in 
				( select post_tags.post_id
					from post_tags, tags
					where tag_name = ? and post_tags.tag_id = tags.id
				)', 
			params[:tag]
		)

		render 'index'
	end
end
