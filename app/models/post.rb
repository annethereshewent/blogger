class Post < ActiveRecord::Base
  belongs_to :user
  has_many :comments
  
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
