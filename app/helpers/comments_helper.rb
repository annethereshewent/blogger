module CommentsHelper
	def printCommentTree commentTree, root
		returnStr = ''
		if commentTree[root].nil?
			return;
		end
		commentTree[root].each do |comment|
			returnStr += printSubtree(commentTree, comment)
		end

		return returnStr
	end

	def printSubtree commentTree, comment
		return "
				<p>#{print_comment(comment)}</p>
				<div style='margin-left:15px;'>
					#{printCommentTree(commentTree, comment.id)}
				</div>
			"	
	end

	def print_comment comment
		replytextboxID = "reply-textbox-#{comment.id}"
		replySelector = "'\##{replytextboxID}'";

		return ' 
		<div class="comment"> 
			<div  style="font-size:small;">	
				<img src="' + comment.user.avatar.url(:thumb) + '" class="profile-thumb">
				<b>' + comment.user.displayname + '</b>
				<i>Posted on:</i> ' + comment.created_at.to_s + ' 
			</div>
			<div class="post">
				<p>' + comment.comment + '</p>
			</div>
			<p style="font-size:small;"><a href="#" onClick="$(' + replySelector + ').show();return false;">Reply</a></p>
		</div>
		<div class="comment-container" id="' + replytextboxID + '">
			<hr>
			<form method="post" action="/comments/' + comment.id.to_s + '/reply" id="reply_form_' + comment.id.to_s + '">
				<textarea class="comment-text" name="comment" id="comment_reply" placeholder="Enter comment here..."></textarea>
				<div class="buttonarea" style="margin-top:10px;margin-left:10px">
					<button type="button" onclick="submit_reply(' + comment.id.to_s + ')" class="comment-submit btn primary sm">Reply</button>&nbsp;&nbsp;&nbsp;<button type="button" class="btn cancel sm" onClick="$(' + replySelector + ').hide();return false;">Cancel</button>
				</div>
				<input type="hidden" name="blog" value="' + comment.user_id.to_s + '">
				<input type="hidden" name="pid" value="' + comment.post_id.to_s + '">
				<input type="hidden" name="authenticity_token" id="authenticity_token_' + comment.id.to_s + '">
			</form>
			<hr>
		</div>
		<div class="content-divider"></div>'
	end
end

