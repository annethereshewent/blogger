class User < ActiveRecord::Base
  	# Include default devise modules. Others available are:
  	# :confirmable, :lockable, :timeoutable and :omniauthable
  	devise :recoverable, :trackable
	
	validates :email, uniqueness: true, presence: true
	validates :displayname, uniqueness:true
	
	has_secure_password
	validates_confirmation_of :password
	
	has_attached_file :avatar, :styles => { medium: "120x120#", thumb: '50x50#', small: '80x80#' }, :default_url => '/images/user_icon.png'
	validates_attachment :avatar,
  		:content_type => { :content_type => ["image/jpeg", "image/gif", "image/png"] }

    has_attached_file :banner, styles: { medium: "600x>" }, default_url: "/images/default_banner.jpg"

    validates_attachment :banner, content_type: { content_type: ["image/jpeg", 'image/gif', "image/png"]}

  	belongs_to :theme, optional: true

	has_many :posts
	has_many :comments
	has_many :friendships

	has_many :friends, through: :friendships

	def encrypted_password_changed?
		false
	end

    def fetch_blog_posts page
        self.posts.order('posts.id desc').includes(:tags).includes(:images).paginate(page: page, per_page: 15)
    end

    def get_json_posts friends = nil, page = 1

        friends = self.friends.where('(sender = ?) or (friendships.accepted = true)', self.id) unless friends

        posts = Post.where("user_id in (#{ friends.map{ |friend| friend.id }.push(self.id).join(',') })")
            .order('id desc')
            .paginate(page: page, per_page: 15)
            .includes(:tags)
            .includes(:images)
            .includes(:user)

        formatted_posts = []
        posts.each_with_index do |post, index|
            formatted_posts[index] = {}
            formatted_posts[index][:id] = post.id
            formatted_posts[index][:created_at] = post.created_at.strftime("%m-%d-%y %I:%M %P")
            formatted_posts[index][:updated_at] = post.updated_at.strftime("%m-%d-%y %I:%M %P")
            formatted_posts[index][:post] = post.post
            formatted_posts[index][:edited] = post.edited
            formatted_posts[index][:num_comments] = post.num_comments
            formatted_posts[index][:avatar] = post.user.avatar.url(:small)
            formatted_posts[index][:username] = post.user.displayname
            formatted_posts[index][:user_id] = post.user.id
            formatted_posts[index][:images] = []
            formatted_posts[index][:tags] = post.tags.map{ |tag| tag.tag_name }
            formatted_posts[index][:user] = post.user.render_hash_user

            post.images.each do |image|
                formatted_posts[index][:images].push(image.file.url(:medium))
            end
        end

        formatted_posts

    end

    def render_hash_user
         {
            user_id: self.id,
            username: self.displayname,
            avatar: self.avatar.url(:medium),
            avatar_small: self.avatar.url(:small),
            avatar_thumb: self.avatar.url(:thumb),
            blog_title: self.blog_title,
            description: self.description,
            email: self.email,
            theme: self.theme.present? ? self.theme.theme_name : 'default',
            text_color: self.text_color,
            background_color: self.background_color,
            banner:  self.banner.url(:medium)
        }
    end

    def get_archive_posts 
        first_post_date = Date.parse(self.posts.limit(1).order('id')[0].created_at.to_s)
   
        last_post_date = Date.parse(self.posts.limit(1).order('id desc')[0].created_at.to_s)
        
        posts = self.posts.where('created_at BETWEEN ? and ?', last_post_date.beginning_of_month.beginning_of_day, last_post_date.end_of_month.end_of_day)
          .order('id desc')
          .includes(:images)

        [
            posts,
            first_post_date,
            last_post_date
        ]
    end

    def fetch_archive_posts_by_date date
        posts = self.posts.where('created_at between ? and ?', date.beginning_of_month.beginning_of_day, date.end_of_month.end_of_day)
          .order('id desc')
          .includes(:images)

        posts
    end
end
