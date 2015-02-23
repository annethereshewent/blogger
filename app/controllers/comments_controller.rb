class CommentsController < ApplicationController
	def index
		@post = Post.find(params[:post_id])
		@user = User.find(params[:user_id])

		@commentTree = Hash.new 
		@comments = @post.comments.order('parent, id')
		@comments.each do |comment|
			if @commentTree[comment.parent].nil?
				@commentTree[comment.parent] = Array.new
			end
			@commentTree[comment.parent] << comment
		end
	end

	def create
		@post = Post.find(params[:pid])
		@post.num_comments += 1
		if @post.comments.create(:comment => params[:comment], :parent => 0, :user_id => session[:userid]) && @post.save
			redirect_to user_post_comments_path(params[:blog], params[:pid])
		else
			flash[:notice] = 'Unable to save comment'
			redirect_to user_post_comments_path(params[:blog], params[:pid])
		end
	end

	def reply
		@post = Post.find(params[:pid])
		@post.num_comments += 1
		if Comment.create(:comment => params[:comment], :parent => params[:comment_id], :user_id => params[:blog], :post_id => params[:pid]) && @post.save
			redirect_to user_post_comments_path(params[:blog], params[:pid])
		else
			flash[:notice] = "Unable to save comment"
			redirect_to user_post_comments_path(params[:blog], params[:pid])
		end
 	end

	private
	def comment_params
  		params.require(:comment).permit(:comment, :parent)
  	end
end
