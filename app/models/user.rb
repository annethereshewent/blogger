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

    has_attached_file :banner, styles: { medium: "600x200" }, default_url: "/images/default_banner.jpg"

    validates_attachment :banner, content_type: { content_type: ["image/jpeg", 'image/gif', "image/png"]}

  	belongs_to :theme, optional: true

	has_many :posts
	has_many :comments
	has_many :friendships

	has_many :friends, through: :friendships

	def encrypted_password_changed?
		false
	end

end
