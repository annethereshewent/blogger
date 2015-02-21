class Comment < ActiveRecord::Base
  belongs_to :user
  belongs_to :post

  def print_comment user_pic
  	replytextboxID = "reply-textbox-#{self.id}"
	replySelector = "'\##{replytextboxID}'";
  	
  	return '
		<div class="comment"> 
			<div  style="font-size:small;">	
				<img src="' + user_pic + '" class="profile-thumb">
				<b>' + self.getUser + '</b>
				<i>Posted on:</i> ' + self.created_at.to_s + ' 
			</div>
			<div class="post">
				<p>' + self.comment + '</p>
			</div>
			<p style="font-size:small;"><a href="#" onClick="$(' + replySelector + ').show();return false;">Reply</a></p>
		</div>
		<div class="comment-container" id="' + replytextboxID + '">
			<hr>
			<form method="post" action="/comments/' + self.id.to_s + '/reply" id="reply_form_' + self.id.to_s + '">
				<textarea class="comment-text" name="comment" id="comment_reply" placeholder="Enter comment here..."></textarea>
				<div class="buttonarea" style="margin-top:10px;margin-left:10px">
					<button type="button" onclick="submit_reply(' + self.id.to_s + ')" class="comment-submit btn primary sm">Reply</button>&nbsp;&nbsp;&nbsp;<button type="button" class="btn cancel sm" onClick="$(' + replySelector + ').hide();return false;">Cancel</button>
				</div>
				<input type="hidden" name="blog" value="' + self.user_id.to_s + '">
				<input type="hidden" name="pid" value="' + self.post_id.to_s + '">
				<input type="hidden" name="authenticity_token" id="authenticity_token_' + self.id.to_s + '">
			</form>
			<hr>
		</div>
		<div class="content-divider"></div>
		'
  end


  def getUser 
  	username = User.select('displayname').find(self.user_id)
  	return username.displayname
  end
end
