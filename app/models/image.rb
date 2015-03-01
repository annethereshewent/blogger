class Image < ActiveRecord::Base
  belongs_to :posts, :dependent => :delete
  has_attached_file :file, :styles => { medium: '420x>', small: '200x>'}
  validates_attachment_content_type :file, :content_type => /\Aimage\/.*\Z/
end
