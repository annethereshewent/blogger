class Image < ActiveRecord::Base
  belongs_to :posts, :dependent => :destroy
  has_attached_file :file, :styles => { medium: '420^', small: '200^'}
  validates_attachment_content_type :file, :content_type => /\Aimage\/.*\Z/
end
