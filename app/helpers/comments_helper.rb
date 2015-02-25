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
				<p>" + render(partial: 'comment', locals: { comment: comment }) + "</p>
				<div style='margin-left:15px;'>
					#{printCommentTree(commentTree, comment.id)}
				</div>
			"	

	end
end

