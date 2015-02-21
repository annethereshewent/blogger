class UsersController < ApplicationController
  
  def login
    if session[:userid]
      redirect_to user_posts_path session[:userid]
    end
  end
  
  def validate
  	returnStr = ""
  	user = User.where("username = ?", params[:user])
  	if user
  		returnStr += "user "
  	end
    if params[:display]
  	  user = User.where("displayname = ?", params[:display])
  	  if user
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
      redirect_to user_posts_path @user
    else
      redirect_to '/users/login', notice: "Username already exists"
    end
  end
  
  def checkLogin
  	@user = User.find_by_username(params[:username])
  	if @user and @user.authenticate(params[:pass])
      session[:username] = @user.username
      session[:userid] = @user.id
  		redirect_to user_posts_path @user
  	else
  		redirect_to '/users/login', notice: "Error logging in: Wrong username or password"
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
      @profile_pic = @user.profile_pic ? @user.profile_pic : '/images/user_icon.png'
    else
      # redirect_to '/users/login', notice: "Account"
      render plain: params.inspect
    end
  end
  
  def update_general
    @user = User.find(params[:id])
    if @user.update(user_params)
      redirect_to edit_user_path @user
    else
      flash[:notice] = "error upploading account information"
      redirect_to edit_user_path @user
    end
  end

  def update_picture
    @user = User.find(params[:id])
    file_io = params[:user][:profile_pic]
    accepted_types = ["image/gif", "image/jpeg", "image/jpg", "image/png", "image/x-png", "image/pjpeg"]
    if accepted_types.include? file_io.content_type
      extension = file_io.content_type.split('/')[1]
      if extension == 'x-png'
        extension = 'png'
      elsif extension == 'pjpeg'
        extension = 'jpg'
      end
      filename = SecureRandom.hex + ".#{extension}"
      File.open(Rails.root.join('public', 'images', filename), 'wb') do |file|
        file.write(file_io.read)
        
        if @user.update(profile_pic:"/images/#{filename}")
          redirect_to edit_user_path session[:userid]
        else
          redirect_to edit_user_path session[:userid], flash: { notice: "Error uploading profile picture." }
        end
      end
    else
      redirect_to edit_user_path @user.id, flash: { notice: "Error uploading picture: File type is not accepted." }
    end
  end

  private
  	def user_params
  		params.require(:user).permit(:username, :displayname, :password, :blog_title, :description, :avatar)
  	end
end
