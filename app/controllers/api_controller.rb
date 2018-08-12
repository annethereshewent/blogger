class ApiController < ApplicationController
    include Common
    protect_from_forgery with: :null_session


    def register
        user = User.new(user_params)

        if (user.save) 
            render json: {
                success: true,
                user: render_hash_user(user),
                posts: []
            }
        else
            render json: {
                success: false,
                message: "registration_failed"
            }
        end

    end

    def update_user 
        if authorize?
            if user = User.update(params[:id], user_params)
                render json: {
                    success: true,
                    user: render_hash_user(user)
                }
            else
                render json: {
                    success: false,
                    message: "user_update_fail"
                }
            end
        end
    end

    def post_comment
        if authorize?
            post = Post.find(params[:pid])
            post.num_comments += 1

            comment = ActionController::Base.helpers.sanitize(params[:comment], tags:  %w(b a i ol ul img li h1 h2 h3, br p), attributes: ['href', 'src'])
            comment = comment.gsub("\n", "<br>")

            if ((comment = Comment.create(comment: comment, parent: params[:parent], user_id: @decoded[:user_id], post_id: params[:pid])) && post.save)
                comment = {
                    id: comment.id,
                    comment: comment.comment,
                    parent: comment.parent,
                    username: comment.user.displayname,
                    avatar: comment.user.avatar.url(:small),
                    indentLevel: params[:indentLevel].to_i
                }

                render json: {
                    success: true,
                    comment: comment 
                }
            else
                render json: {
                    success: false,
                    message: "comment_creation_failed"
                }
            end
        end
    end

    def login
        if (!params[:username] || !params[:password])
            render json: {
                success: false,
                message: "bad_request"
            }
        else
            @user = User.find_by_email(params[:username])
            if @user and @user.authenticate(params[:password])
                @friends = @user.friends.where('(sender = ?) or (friendships.accepted = true)', @user.id) 
                formatted_posts = get_json_posts(@user, @friends)

                render json: {
                    success: true,
                    user: render_hash_user(@user),
                    posts: formatted_posts
                }
            else
                render json: {
                    success: false,
                    message: "login_failed"
                }
            end
        end
    end

    def switch_theme 
        if authorize?
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

    def verify
        puts params[:id]
        @user = User.select('password_digest').find(params[:id])
        if @user.authenticate(params[:password])
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
            token: encode(user_id: user.id),
            avatar_thumb: user.avatar.url(:thumb),
            blog_title: user.blog_title,
            description: user.description,
            email: user.email,
            theme: user.theme.present? ? user.theme.theme_name : 'default'

        }
    end


    def fetch_posts
        if authorize?
            # fetch the posts
            user = User.find(@decoded[:user_id])
            formatted_posts = params[:page].present? ? get_json_posts(user, nil, params[:page].to_i) : get_json_posts(user)

            render json: {
                success: true,
                posts: formatted_posts,
                user: {
                    user_id: user.id,
                    username: user.displayname,
                    avatar_thumb: user.avatar.url(:thumb)
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

    def tag_search 
        if authorize? 
            puts params[:tag]
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

            render json: {
                success: true,
                user: render_hash_user(user),
                posts: posts.map{ |post| render_hash_post(post) }
            }
        else
            render json: {
                success: false,
                message: "user_not_found"
            }
        end

    end

    def authorize? 
        unless request.headers["Authorization"]
            render json: {
                success: false,
                message: "unauthorized"
            }
            return false
        end

        @decoded = decode(request.headers["Authorization"])

        if @decoded.is_a?(Hash) && @decoded[:user_id]
            return true
        end
        
        render json: {
            success: false,
            message: "invalid_token"
        }

        return false
    end


    def sanitize_post
        params[:client] == "web" && request.headers["origin"] == ENV["ANGULAR_SERVER"] ? params[:post] : ActionController::Base.helpers.sanitize(params[:post], tags:  %w(b a i ol ul img li h1 h2 h3, br p), attributes: ['href', 'src'])
    end

    def create_post
        # first we need to verify that the user sending the request is authenticated (check their token)
        if authorize?
            # the token is valid. create a post for this user.
            @user = User.find(@decoded[:user_id])

            if @user
                # we need to sanitize the html first since this is coming from a mobile app, not from the rails app
                contents = sanitize_post

                if post = Post.create(post: contents, user_id: @decoded[:user_id])
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
            else
                render json: {
                    success: false,
                    message: "invalid_user"
                }
            end 
        end  
    end

    def upload_image
        if authorize?
            if post = Post.create(user_id: @decoded[:user_id], post: '')
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
        if authorize?
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
        if authorize?
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

    def encode(payload, exp = 24.hours.from_now)
        payload[:exp] = exp.to_i
        JWT.encode(payload, Rails.application.secrets.secret_key_base)
    end

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
        if authorize?
            # fetch friends
            user = User.find(@decoded[:user_id])
            friends = user.friends.where('(sender = ?) or (friendships.accepted = true)', user.id)

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
           {
                id: comment.id,
                comment: comment.comment,
                parent: comment.parent,
                username: comment.user.displayname,
                avatar: comment.user.avatar.url(:small),
            }
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

        render json: {
            success: true,
            comments: comments,
            num_comments: comments.length
        }
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

    def decode(token)
        body = JWT.decode(token, Rails.application.secrets.secret_key_base)[0]
        HashWithIndifferentAccess.new body
    rescue
        nil
    end

    private
        def user_params
            params.permit(:blog_title, :email, :displayname, :password, :description, :avatar, :theme)
        end
end