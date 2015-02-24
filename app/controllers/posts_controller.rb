class PostsController < ApplicationController
	def index
		page = params[:page].present? ? params[:page].to_i : 1

		@user = User.find(params[:user_id])
		@posts = @user.posts.order('posts.id desc').includes(:tags).order('post_tags.created_at').page(page).per(18)
	end

	def create
		if @post = Post.create(post: params[:htmlContent], user_id: params[:user_id])
			parse_tags(params[:tags])
			redirect_to user_posts_page_path(params[:user_id], 1)

		else
			flash[:notice] = "Could not save post"
			redirect_to user_posts_page_path(params[:user_id], 1)
		end
	end
	
	def update
		if @post = Post.update(params[:id], post: params[:htmlContent], edited: 1)
			parse_tags(params[:tags])
			redirect_to user_posts_page_path(params[:user_id], 1)
		else
			flash[:notice] = "Unable to update post"
			redirect_to user_posts_page_path(params[:user_id], 1)
		end
	end

	def parse_tags(tags)
		tags.split(',').each do |tag|
			if (@tag = Tag.where('tag_name = ? ', tag)).present?
				PostTag.create(tag_id: @tag[0].id, post_id: @post.id)
			else
				@tag = Tag.create(tag_name: tag)
				PostTag.create(tag_id: @tag.id, post_id: @post.id)
			end
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
							:tags 	 => @post.tags.order('post_tags.created_at desc').map { |tag| tag.tag_name }
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
		@posts = @user.posts.order('id desc').where(
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
