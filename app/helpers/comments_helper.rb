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
		replytextboxID = "reply-textbox-#{comment.id}"
		replySelector = "'\##{replytextboxID}'";

		comment_render = render partial: 'comment', locals: {
			:comment => comment,
			:replytextboxID => replytextboxID,
			:replySelector => replySelector
		}

		return "
				<p>#{comment_render}</p>
				<div style='margin-left:15px;'>
					#{ printCommentTree(commentTree, comment.id) }
				</div>
			"	

	end
end

