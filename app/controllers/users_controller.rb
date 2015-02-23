class UsersController < ApplicationController
  
  def login
    if session[:userid]
      redirect_to user_posts_page_path(session[:userid], 1) 
    end
  end
  
  def validate
  	returnStr = ""
  	user = User.find_by_username(params[:user])
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
  
  def create
    @user = User.new(user_params)
    if @user.save
      session[:username] = @user.username
      session[:userid]   = @user.id
      redirect_to user_posts_page_path(@user, 1)
    else
      redirect_to '/users', notice: "Username already exists"
    end
  end
  
  def checkLogin
  	@user = User.find_by_username(params[:username])
  	if @user and @user.authenticate(params[:pass])
      session[:username] = @user.username
      session[:userid] = @user.id
  		redirect_to user_posts_page_path(@user, 1)
  	else
      flash[:notice] = "Error logging in: Wrong username or password"
  		redirect_to '/users'
  	end 
  end

  def verify
    @user = User.select('password_digest').find_by_username(params[:username])
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
    if session[:userid].to_i == params[:id].to_i
      @user = User.find(params[:id])
      # @profile_pic = @user.profile_pic ? @user.profile_pic : '/images/user_icon.png'
    else
      # redirect_to '/users/login', notice: "Account"
      flash[:notice] = "Unable to access control panel: access denied"
      redirect_to '/users/login'
    end
  end
  
  def update
    if User.update(params[:id], user_params)
      redirect_to user_account_path params[:id]
    else
      flash[:notice] = "error upploading account information"
      redirect_to user_account_path params[:id]
    end
  end

  def update_picture
     if User.update(session[:userid], user_params)
      redirect_to user_account_path session[:userid]
    else
      redirect_to user_account_path session[:userid], flash: { notice: "Error uploading picture." }
    end
  end


  private
  	def user_params
  		params.require(:user).permit(:username, :displayname, :password, :blog_title, :description, :avatar)
  	end
end
