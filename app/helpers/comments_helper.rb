module CommentsHelper
	def printCommentTree commentTree, root
		returnStr = ''
		if commentTree[root].nil?
			return;
		end
		commentTree[root].each do |comment|
			returnStr += printSubtree(commentTree, comment)
		end

		returnStr.html_safe
	end

	def printSubtree commentTree, comment
		replytextboxID = "reply-textbox-#{comment.id}"
		replySelector = "'\##{replytextboxID}'";

		render partial: 'comment', locals: {
			comment: comment,
			replytextboxID: replytextboxID,
			replySelector: replySelector,
			commentTree: commentTree
		}
	end
end

