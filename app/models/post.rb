class Post < ActiveRecord::Base
  belongs_to :user
  has_many :comments
  has_many :post_tags
  has_many :tags, :through => :post_tags
  has_many :images
  
  def getCommentText
  	case self.num_comments
  	when 0
  		return 	'Comments'
  	when 1
  		return "1 Comment"
  	else
  		return "#{num_comments} Comments"
  	end
  end
end
