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

  def parse_tags(tags)
    if !tags.is_a?(Array)
      tags = tags.split(',')
    end

    self.tags.destroy_all

    tags.each do |tag|
      if (@tag = Tag.where('tag_name = ? ', tag)).present?
        PostTag.create(tag_id: @tag[0].id, post_id: self.id)
      else
        @tag = Tag.create(tag_name: tag)
        PostTag.create(tag_id: @tag.id, post_id: self.id)
      end
    end
  end

  def self.tagSearch tag
    posts = Post.order('posts.id desc')
      .includes(:tags)
      .includes(:images)
      .where('posts.id in (
          select post_tags.post_id
          from post_tags, tags
          where post_tags.tag_id = tags.id and tags.tag_name = ?
        )
      ', tag)

    posts
  end

end
