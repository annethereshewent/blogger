class User < ActiveRecord::Base
	validates :username, uniqueness: true, presence: true
	validates :displayname, uniqueness:true
	has_secure_password
	has_attached_file :avatar, :styles => { medium: "120x120", thumb: '50x50'}, :default_url => '/images/user_icon.png'
	validates_attachment_content_type :avatar, :content_type => /\Aimage\/.*\Z/

	has_many :posts
	has_many :comments
end
