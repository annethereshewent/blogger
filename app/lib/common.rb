module Common
    def post_search search_term
        search_params = search_term.split(' ').map{ |token| "%#{token}%" }.join('')



        @posts = Post
            .where('post LIKE ? or id in (
                select post_tags.post_id
                from post_tags, tags
                where post_tags.tag_id = tags.id and tags.tag_name LIKE ? 
              )', 
                search_params, search_params)
            .order('id desc')
    end
end
