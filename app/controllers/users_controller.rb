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

  def fetch_posts 

    @friends = User.where("id in (#{params[:friend_ids]})")
    @user =  @friends[ @friends.index { |friend| friend.id == session[:userid] } ]
    @posts = Post.where("posts.user_id in (#{params[:friend_ids]})").order('posts.id desc')
            .paginate(page: params[:page], per_page: 15)
            .includes(:tags)
            .includes(:images)
            .includes(:user)

    render partial: 'dashPosts'
  end

  def get_user_id 
    unless params[:username]
      render plain: 'error'
    end

    user = User.where('displayname = ?', params[:username])

    if user.count == 1
      render plain: user[0].id
    else
      render plain: 'error'
    end
  end

  def dashboard
    unless (session[:userid] && session[:userid] == params[:user_id].to_i)
      return redirect_to '/users'
    end

    if @user = User.find(session[:userid])
      @friends = @user.friends.where('(sender = ?) or (friendships.accepted = true)', @user.id)
      
      @posts = Post.where("user_id in (#{ @friends.map{ |friend| friend.id }.push(@user.id).join(',') })")
        .limit(15)
        .order('id desc')
        .includes(:tags)
        .includes(:images)
        .includes(:user)

    else
      flash[:notice] = "An Error has occurred"
      redirect_to 'users'
    end
  end

  def search
    @user = User.find(session[:userid])

    search_params = params[:search].split(' ').map{ |token| "%#{token}%" }.join(' ')

    @posts = Post.where('post LIKE ?', search_params).order('id desc')

    render 'dash_search'
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
      friendships = Friendship.where('user_id = ? and accepted = false and sender <> user_id', session[:userid]).limit(2)
      
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

  def switch_theme
    if User.update(session[:userid], theme_id: params[:theme_id])
      render plain: 'success'
    else
      render plain: 'failure'
    end
  end

  def isFriends
    @user = User.find(params[:user_id])
    friends = @user.friends.where('friendships.accepted = true and users.displayname = ?', params[:username])
    if friends.present?
      render plain: 'true'
    else
      render plain: friends.inspect
    end
  end

  def tags
    params[:tag].gsub!('-', ' ')

    @user = User.find(session[:userid])
    @posts = Post.order('posts.id desc')
              .includes(:tags)
              .includes(:images)
              .where('posts.id in (
                                    select post_tags.post_id
                                    from post_tags, tags
                                    where post_tags.tag_id = tags.id and tags.tag_name = ?
                                  )
              ', params[:tag])

    render 'dash_search'
  end

  private
  	def user_params
  		params.require(:user).permit(:email, :displayname, :password, :blog_title, :description, :avatar, :theme)
  	end
end
