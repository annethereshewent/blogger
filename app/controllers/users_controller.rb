class UsersController < ApplicationController
  
  def login
    if session[:userid]
      redirect_to user_dashboard_path session[:userid] 
    end
  end
  
  def validate
  	returnStr = ""
  	user = User.find_by_email(params[:user])
  	if user
  		returnStr += "user "
  	end
    if params[:display] != ''
  	  user = User.where("displayname = ?", params[:display])
  	  if user.count > 0 
  		  returnStr += " display"
      end
  	end
  	render plain: returnStr
  end

  def dashboard
    unless (session[:userid] == params[:user_id].to_i)
      redirect_to '/users'
    end

    @user = User.find(session[:userid])
    @friends = @user.friends.where('friendships.accepted = true').includes(:posts)
    
    @posts = []
    
    @friends.each do |friend|
      friend.posts.includes(:tags).each do |post|
        @posts << post
      end
    end

    # include logged in user's posts as well
    @user.posts.includes(:tags).each do |post|
      @posts << post
    end

    @posts.sort! do |a,b|
      b.id <=> a.id
    end

  end
  
  def create
    @user = User.new(user_params)
    if @user.save
      session[:username] = @user.email
      session[:userid]   = @user.id
      redirect_to user_dashboard_path @user.id
    else
      redirect_to '/users', notice: "Username already exists"
    end
  end
  
  def checkLogin
  	@user = User.find_by_email(params[:username])
  	if @user and @user.authenticate(params[:pass])
      session[:username] = @user.email
      session[:userid] = @user.id
  		redirect_to user_dashboard_path @user
  	else
      flash[:notice] = "Error logging in: Wrong username or password"
  		redirect_to '/users'
  	end 
  end

  def verify
    @user = User.select('password_digest').find_by_email(params[:username])
    if @user.authenticate(params[:password])
      render plain: 'true'
    else
      render plain: 'false'
    end
  end

  def logout
    reset_session
    redirect_to users_path
  end

  def account
    if session[:userid].present? && session[:userid].to_i == params[:id].to_i
      @user = User.find(params[:id])
      # @profile_pic = @user.profile_pic ? @user.profile_pic : '/images/user_icon.png'
    else
      # redirect_to '/users', notice: "Account"
      flash[:notice] = "Please log in to continue"
      redirect_to '/users'
    end
  end
  
  def update
    if User.update(params[:id], user_params)
      redirect_to user_account_path params[:id]
    else
      flash[:notice] = "Error updating account information"
      redirect_to user_account_path params[:id]
    end
  end

  def add_friend
    unless session[:userid]
      return render plain: 'false'
    end

    if Friendship.create(user_id: session[:userid], friend_id: params[:user_id], accepted: false, sender: session[:userid]) && Friendship.create(user_id: params[:user_id], friend_id: session[:userid], accepted: false, sender: session[:userid])
      render plain: "true"
    else
      render plain: "false"
    end
  end

  def get_requests 
    if session[:userid] && params[:num].to_i > 0 
      friendships = Friendship.where('user_id = ? and accepted = ? and sender <> user_id', session[:userid], false).limit(2)
      
      friendship_str = friendships.map{ |friendship| friendship.friend_id }.join(',')
      
      users = User.where("id in (#{friendship_str})")
      render partial: 'friendships', locals: { users: users }
    else
      render plain: 'N/A'
    end
  end

  def confirm_friend
    Friendship.where('(user_id = ? and friend_id = ?) or (user_id = ? and friend_id=?)', params[:id], params[:user_id], params[:user_id], params[:id]).update_all(:accepted => true)

    redirect_to user_dashboard_path params[:id]
  end

  private
  	def user_params
  		params.require(:user).permit(:email, :displayname, :password, :blog_title, :description, :avatar)
  	end
end
