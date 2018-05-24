 class UsersController < ApplicationController
  def login
    if session[:userid]
      redirect_to user_dashboard_path 
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

  def play_game 
    unless (session[:userid])
      return redirect_to '/users', notice: "Please log in to continue"
    end

    @username = User.find(session[:userid]).displayname

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
    unless (session[:userid])
      return redirect_to '/users', notice: "Please log in to continue"
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

    search_params = params[:search].split(' ').map{ |token| "%#{token}%" }.join('')



    @posts = Post.where('post LIKE ? or id in (
        select post_tags.post_id
        from post_tags, tags
        where post_tags.tag_id = tags.id and tags.tag_name LIKE ? 
      )', 
      search_params, search_params).order('id desc')

    render 'dash_search'
  end
  
  def create
    @user = User.new(user_params)
    test_user = User.find_by_email(@user.email)

    puts "username with that email found" if test_user
    
    if @user.save
      session[:username] = @user.email
      session[:userid]   = @user.id
      redirect_to user_dashboard_path
    else
      redirect_to '/users', notice: "Unable to create user"
    end
  end
  
  def checkLogin
  	@user = User.find_by_email(params[:username])
  	if @user and @user.authenticate(params[:pass])
      session[:username] = @user.email
      session[:userid] = @user.id
  		redirect_to user_dashboard_path
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
    if session[:userid].present?
      @user = User.find(session[:userid])
      # @profile_pic = @user.profile_pic ? @user.profile_pic : '/images/user_icon.png'
    else
      # redirect_to '/users', notice: "Account"
      flash[:notice] = "Please log in to continue"
      redirect_to '/users'
    end
  end
  
  def update
    if User.update(params[:id], user_params)
      redirect_to user_account_path 
    else
      flash[:notice] = "Error updating account information"
      redirect_to user_account_path
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

  def fetch_archive_posts 
    unless params[:user_id] && params[:date]
      render plain: 'false'
    end
    @user = User.find(params[:user_id])

    date = Date.parse(params[:date])

    @posts = @user.posts.where('created_at between ? and ?', date.beginning_of_month.beginning_of_day, date.end_of_month.end_of_day)
      .order('id desc')
      .includes(:images)

    render partial: 'archive_posts'
  end

  def archive
    # params[:user_id] tells you who to get the archive for, initially load the posts for current month
    unless params[:user_id]
      return redirect_to '/users', notice: 'Please log in to continue'
    end

    @user = User.find(params[:user_id])

    @first_post_date = Date.parse(@user.posts.limit(1).order('id')[0].created_at.to_s)
   
    @last_post_date = Date.parse(@user.posts.limit(1).order('id desc')[0].created_at.to_s)


    months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ]
    
    @posts = @user.posts.where('created_at BETWEEN ? and ?', @last_post_date.beginning_of_month.beginning_of_day, @last_post_date.end_of_month.end_of_day)
      .order('id desc')
      .includes(:images)


    @select = {}

    first_year = @first_post_date.year
    last_year = @last_post_date.year



    (@first_post_date.year..@last_post_date.year).each do |year|
      @select[year] = []
      if year == @first_post_date.year
        i = @first_post_date.month-1
        
        last_index = @first_post_date.year == @last_post_date.year ? @last_post_date.month : months.length

        while i <  last_index
          date = Date.parse("#{months[i]} #{year}")

          if (@user.posts.where('created_at BETWEEN ? and ?', date.beginning_of_month.beginning_of_day, date.end_of_month.end_of_day).count > 0)
            @select[year].push(months[i])
          end
          i = i+1
        end
      elsif year == @last_post_date.year
        months.each_with_index do |month, index|
          if index == @last_post_date.month
            break
          end
          date = Date.parse("#{month} #{year}")
          if (@user.posts.where('created_at BETWEEN ? and ?', date.beginning_of_month.beginning_of_day, date.end_of_month.end_of_day).count > 0)
            @select[year].push(month) 
          end
        end
      else
        months.each do |month|
          date = Date.parse("#{month} #{year}")
          if (@user.posts.where('created_at BETWEEN ? and ?', date.beginning_of_month.beginning_of_day, date.end_of_month.end_of_day).count > 0)
            @select[year].push(month)
          end
        end
        
      end
    end
    @select = @select.to_json
  end

  def confirm_friend
    Friendship.where('(user_id = ? and friend_id = ?) or (user_id = ? and friend_id=?)', params[:id], params[:user_id], params[:user_id], params[:id]).update_all(:accepted => true)

    redirect_to user_dashboard_path
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
