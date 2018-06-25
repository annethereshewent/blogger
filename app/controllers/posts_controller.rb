class PostsController < ApplicationController	
	protect_from_forgery :except => [:upload_image]

	def index
		page = params[:page].present? ? params[:page].to_i : 1

		@user = User.find(params[:user_id])
		@posts = @user.posts.order('posts.id desc').includes(:tags).includes(:images).paginate(page: params[:page], per_page: 15)

	end

	def create
		# parse any urls in the post content and add <a> tags to them
		content = params[:htmlContent].present? ? params[:htmlContent] : params[:youtube_content]

		if @post = Post.create(post: content, user_id: params[:user_id])
			parse_tags(params[:tags])
			if params[:source] == 'dashboard' || params[:youtube_content].present?
				redirect_to user_dashboard_path
			else
				redirect_to user_posts_page_path(params[:user_id], 1)
			end

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

	def fetch_sidebar_posts
		@user = User.find(session[:userid])

		@posts = @user.posts.order('posts.id desc')
			.includes(:tags)
			.includes(:images)
			.paginate(page: params[:page], per_page: 15)

		render partial: '/users/sidebar_posts'
	end

	def fetch 
		@post = Post.find(params[:post_id])
		user = @post.user
		if @post
			render json: {
				status: true,
				content: @post.post,
				images: @post.images.map{ |image| image.file.url(:medium) },
				user: {
						displayname: user.displayname,
						id: user.id
			    },
				tags: @post.tags.order('post_tags.created_at desc').map { |tag| tag.tag_name }
	  		}			
		else
			render json: {
				status: false
	  	 	}
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

	def upload_image
		file = params[:file]


		image = Image.create({
			file: params[:file]
		})

		render json: {
			link: image.file.url
		}
	end

	def upload_images
		if @post = Post.create(user_id: session[:userid], post: '')
			if @post.images.create(post_params)
				parse_tags(params[:tags])
				if request.xhr?
					render plain: 'success'
				else
					redirect_to user_dashboard_path session[:userid]
				end
			else
				flash[:notice] = "Unable to save image"
				if request.xhr?
					render plain: 'failure'
				else
					redirect_to user_dashboard_path session[:userid]
				end
			end
		else
			flash[:notice] = "Unable to save image"
			redirec_to user_dashboard_path session[:userid]
		end
	end

	private
	  	def post_params
	  		params.require(:post).permit(:file)
	  	end
end
