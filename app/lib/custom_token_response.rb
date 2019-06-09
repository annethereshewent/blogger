module CustomTokenResponse
  def body
    user = User.find(@token.resource_owner_id)

    friends = user.friends.where('(sender = ?) or (friendships.accepted = true)', user.id)
    formatted_posts = user.get_json_posts(friends)

    additional_data = {
        user: user.render_hash_user(),
        posts: formatted_posts
    }

    # call original `#body` method and merge its result with the additional data hash
    super.merge(additional_data)
  end
end