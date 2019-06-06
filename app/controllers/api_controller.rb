class ApiController < ApplicationController
    include Common
    protect_from_forgery with: :null_session

    before_action :doorkeeper_authorize!, :current_resource_owner

    def is_friends
        if @user.present?
            friends = @user.friends.where('friendships.accepted = true and users.displayname = ?', params[:friend])

            if friends.present?
                render json: {
                    success: true,
                    is_friend: true
                }
            else
                render json: {
                    success: true,
                    is_friend: false
                }
            end
        end

    end

    def current_resource_owner
        if doorkeeper_token
            @user = User.find(doorkeeper_token.resource_owner_id) 
        else
            render json: {
                success: false,
                message: "user not found"
            }
        end
    end

    def update_user 
        if @user.present? and @user.update(user_params)
            render json: {
                success: true,
                user: render_hash_user(@user)
            }
        else
            render json: {
                success: false,
                message: "user_update_fail"
            }
        end

    end

    def post_comment
        if @user.present?
            return render json: {
                success: true
            }

            unless params[:indentLevel] && params[:comment] && params[:pid] && params[:parent]
                return render json: {
                    success: false,
                    message: "bad_request"
                }
            end

            post = Post.find(params[:pid])
            post.num_comments += 1

            comment = ActionController::Base.helpers.sanitize(params[:comment], tags:  %w(b a i ol ul img li h1 h2 h3, br p), attributes: ['href', 'src'])
            comment = comment.gsub("\n", "<br>")

            if ((comment = Comment.create(comment: comment, parent: params[:parent], user_id: @user.id, post_id: params[:pid])) && post.save)
                comment = render_hash_comment(comment)
                comment[:indentLevel] = params[:indentLevel].to_i

                render json: {
                    success: true,
                    comment:  comment
                }
            else
                render json: {
                    success: false,
                    message: "comment_creation_failed"
                }
            end
        end
    end

    def fetch_user 
        if @user.present?
            friends = @user.friends.where('(sender = ?) or (friendships.accepted = true)', @user.id)
            formatted_posts = get_json_posts(@user, friends)

            render json: {
                success: true,
                user: render_hash_user(@user),
                posts: formatted_posts
            }
        end
    end

    def switch_theme 
        if @user.present?
            unless params[:theme_id]
                return render json: {
                    success: false,
                    message: "bad_request"
                }
            end

            if User.update(@decoded[:user_id], theme_id: params[:theme_id])
                render json: {
                    success: true
                }
            else
                render json: {
                    success: false,
                    message: "theme_update_fail"
                }
            end

        end
    end

    # leave this for now but we can remove it later and use the oauth route instead
    def verify
        user = User.select('password_digest').find(params[:id])
        if user.authenticate(params[:password])
            render json: {
                success: true
            }
        else
            render json: {
                success: false
            }
        end
    end

    def render_hash_user user
         {
            user_id: user.id,
            username: user.displayname,
            avatar: user.avatar.url(:medium),
            avatar_small: user.avatar.url(:small),
            avatar_thumb: user.avatar.url(:thumb),
            blog_title: user.blog_title,
            description: user.description,
            email: user.email,
            theme: user.theme.present? ? user.theme.theme_name : 'default'

        }
    end


    def fetch_posts
        if @user.present?
            formatted_posts = params[:page].present? ? get_json_posts(@user, nil, params[:page].to_i) : get_json_posts(@user)

            render json: {
                success: true,
                posts: formatted_posts,
                user: {
                    user_id: @user.id,
                    username: @user.displayname,
                    avatar_thumb: @user.avatar.url(:thumb)
                }
            }
        end
    end

    def render_hash_post post
        {                    
            id: post.id,
            created_at: post.created_at.strftime("%m-%d-%y %I:%M %P"),
            updated_at: post.updated_at.strftime("%m-%d-%y %I:%M %P"),
            post: post.post,
            edited: post.edited,
            num_comments: post.num_comments,
            avatar: post.user.avatar.url(:small),
            username: post.user.displayname,
            user_id: post.user.id,
            images: post.images.map { |image| image.file.url(:medium) } ,
            tags: post.tags.map{ |tag| 
                tag.tag_name
            }
        }
    end

    def render_hash_comment comment 
        {
            id: comment.id,
            comment: comment.comment,
            parent: comment.parent,
            username: comment.user.displayname,
            avatar: comment.user.avatar.url(:small),
            avatar_thumb: comment.user.avatar.url(:thumb),
            created_at: comment.created_at.strftime("%m-%d-%y %I:%M %P"),
            updated_at: comment.updated_at.strftime("%m-%d-%y %I:%M %P")
        }
    end

    def tag_search 
        if @user.present? 
            posts = Post.tagSearch(params[:tag_name])

            render json: {
                success: true,
                posts: posts.map{ |post| render_hash_post post}
            }
        end
    end

    def fetch_blog_posts
        unless params[:username]
            return render json: {
                success: false,
                message: "bad_request"
            }
        end

        page = params[:page].present? ? params[:page] : 1

        user = User.where('displayname = ?', params[:username])[0]

        if user
            posts = user.fetch_blog_posts(page)

            json_object = {
                success: true,
                posts: posts.map { |post| render_hash_post(post) },
                user: render_hash_user(user),
                pagination: {
                    next_page: posts.next_page,
                    page: page,
                    prev_page: posts.previous_page
                }
            }

            render json: json_object
        else
            render json: {
                success: false,
                message: "user_not_found"
            }
        end

    end

    def sanitize_post
        params[:client] == "web" && request.headers["origin"] == ENV["ANGULAR_SERVER"] ? params[:post] : ActionController::Base.helpers.sanitize(params[:post], tags:  %w(b a i ol ul img li h1 h2 h3, br p), attributes: ['href', 'src'])
    end

    def create_post
        # first we need to verify that the user sending the request is authenticated (check their token)
        if @user.present?
            # the token is valid. create a post for this user.
            # we need to sanitize the html first since this is coming from a mobile app, not from the rails app
            contents = sanitize_post

            if post = @user.posts.create(post: contents)
                if (params[:tags].present?)
                    post.parse_tags(params[:tags])
                end

                render json: {
                    success: true,
                    post: render_hash_post(post)
                }
            else
                render json: {
                    success: false,
                    message: "post_create_failed"
                }
            end

        end  
    end

    def upload_image
        if @user.present?
            if post = @user.posts.create(post: '')
                if post.images.create(file: params[:file])
                    render json: {
                        success: true,
                        post: render_hash_post(post)
                    }
                else
                    render json: {
                        success: false,
                        message: "image_creation_failed"
                    }
                end
            else
                render json: {
                    success: false,
                    message: "post_creation_failed"
                }
            end
        end
    end

    def delete_post
        if @user.present?
            if Post.destroy(params[:post_id])
                render json: {
                    success: true
                }
            else
                render json: {
                    success: false,
                    message: "post_deletion_fail"
                }
            end
        end
    end

    def edit_post
        if @user.present?
            unless params[:post] && params[:id]
                return render json: {
                    success: false,
                    message: "invalid_params"
                }
            end

            contents = sanitize_post

            if post = Post.update(params[:id], post: contents, edited: 1)
                if params[:tags]
                    post.parse_tags(params[:tags])
                end

                post = Post.find(params[:id])

                render json: {
                    success: true,
                    post: render_hash_post(post)
                }

            else
                render json: {
                    success: false,
                    message: "post_edit_fail"
                }
            end
        end
    end

    # def encode(payload, exp = 24.hours.from_now)
    #     payload[:exp] = exp.to_i
    #     JWT.encode(payload, Rails.application.secrets.secret_key_base)
    # end

    def get_json_posts user, friends = nil, page = 1

        friends = user.friends.where('(sender = ?) or (friendships.accepted = true)', user.id) unless friends

        posts = Post.where("user_id in (#{ friends.map{ |friend| friend.id }.push(user.id).join(',') })")
            .order('id desc')
            .paginate(page: page, per_page: 15)
            .includes(:tags)
            .includes(:images)
            .includes(:user)

        formatted_posts = []
        posts.each_with_index do |post, index|
            formatted_posts[index] = {}
            formatted_posts[index][:id] = post.id
            formatted_posts[index][:created_at] = post.created_at.strftime("%m-%d-%y %I:%M %P")
            formatted_posts[index][:updated_at] = post.updated_at.strftime("%m-%d-%y %I:%M %P")
            formatted_posts[index][:post] = post.post
            formatted_posts[index][:edited] = post.edited
            formatted_posts[index][:num_comments] = post.num_comments
            formatted_posts[index][:avatar] = post.user.avatar.url(:small)
            formatted_posts[index][:username] = post.user.displayname
            formatted_posts[index][:user_id] = post.user.id
            formatted_posts[index][:images] = []
            formatted_posts[index][:tags] = post.tags.map{ |tag| tag.tag_name }

            post.images.each do |image|
                formatted_posts[index][:images].push(image.file.url(:medium))
            end
        end

        formatted_posts

    end

    def fetch_friends
        if @user.present?
            # fetch friends
            friends = @user.friends.where('(sender = ?) or (friendships.accepted = true)', @user.id)

            render json: {
                success: true, 
                friends: friends.map{ |friend|
                    {
                        user_id: friend.id,
                        username: friend.displayname,
                        avatar: friend.avatar.url(:small)
                    }
                }
            } 
        end
    end

    def fetch_comments
        post = Post.find(params[:post_id])

        comments = post.comments.order('comments.parent, comments.id').joins(:user).map{ |comment| 
           render_hash_comment(comment)
        }

        commentTree = {}

        comments.each do |comment|
            if commentTree[comment[:parent]].nil?
                commentTree[comment[:parent]] = []
            end
            commentTree[comment[:parent]] << comment

        end

        # next we need to convert the comment tree into an array of comments, in the order to print them, with a new param: indentLevel, added to each comment
        comments = searchCommentTree(commentTree, 0, 0)

        if comments.nil? 
            comments = []
        end

        response = {
            success: true,
            post: render_hash_post(post),
            comments: comments,
            num_comments: comments.length
        }

        if params[:username].present?
            user = User.where('displayname = ?', params[:username])[0]
            response[:user] = render_hash_user(user)
        end

        render json: response
    end

    def find_user
        user = User.where('displayname = ?', params[:username])

        if user.count > 0
            return render json: {
                duplicate: true
            }
        end

        return render json: {
            duplicate: false
        }
    end

    def find_email
        user = User.find_by_email(params[:email])

        if user
            return render json: {
                duplicate: true
            }
        end

        return render json: {
            duplicate: false
        }
    end

    def search
        if @user.present?
            post_search(params[:search_term])

            render json: {
                success: true,
                posts: @posts.map{ |post| render_hash_post(post) }
            }

        end
    end

    def searchCommentTree commentTree, root, indentLevel
        if commentTree[root].nil?
            return;
        end

        comments = []

        commentTree[root].each do |comment|
            next if comment.nil?

            comment[:indentLevel] = indentLevel
            comments << comment


            newLevel = indentLevel + 1
            comments.push(*searchCommentTree(commentTree, comment[:id], newLevel))
        end

        comments

    end

    # def decode(token)
    #     body = JWT.decode(token, Rails.application.secrets.secret_key_base)[0]
    #     HashWithIndifferentAccess.new body
    # rescue
    #     nil
    # end

    private
        def user_params
            params.permit(:blog_title, :email, :displayname, :password, :description, :avatar, :theme)
        end
end