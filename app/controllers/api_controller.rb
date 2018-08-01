class ApiController < ApplicationController
    protect_from_forgery with: :null_session


    def register
        user = User.new(user_params)

        if (user.save) 
            render json: {
                success: true,
                token: encode(user_id: user.id),
                user_id: user.id,
                username: user.email,
                posts: []
            }
        else
            render json: {
                success: false,
                message: "registration_failed"
            }
        end

    end

    def post_comment
        unless params[:token] && params[:comment] && params[:parent] && params[:indentLevel] && params[:pid]
            render json: {
                success: false,
                message: "bad_request"
            }
        end

        decoded = decode(params[:token])

        if (decoded.is_a?(Hash) && decoded[:user_id]) 
            post = Post.find(params[:pid])
            post.num_comments += 1

            if ((comment = Comment.create(comment: params[:comment], parent: params[:parent], user_id: decoded[:user_id], post_id: params[:pid])) && post.save)
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
        else
            render json: {
                success: false,
                message: "invalid_token"
            }

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
                    token: encode(user_id: @user.id),
                    user_id: @user.id,
                    username: @user.displayname,
                    avatar: @user.avatar.url(:thumb),
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

    def fetch_posts
        unless (params[:token] && params[:token].length > 0) 
            render json: {
                success: false,
                message: "bad_request"
            }
        else
            decoded = decode(params[:token])
            if (decoded.is_a?(Hash) && decoded[:user_id])
                # fetch the posts
                user = User.find(decoded[:user_id])
                formatted_posts = get_json_posts(user)

                render json: {
                    success: true,
                    posts: formatted_posts,
                    user_id: user.id,
                    username: user.displayname,
                    avatar: user.avatar.url(:thumb)
                }

            else
                render json: {
                    success: false,
                    message: "invalid_token"
                }
            end
        end
    end
    def create_post
        # first we need to verify that the user sending the request is authenticated (check their token)
        unless (params[:token] && params[:post]) 
            render json: {
                success: false
            }
        else
            # check the token
            decoded = decode(params[:token])

            if (decoded.is_a?(Hash) && decoded[:user_id]) 
                # the token is valid. create a post for this user.
                @user = User.find(decoded[:user_id])

                if @user
                    # we need to sanitize the html first since this is coming from a mobile app, not from the rails app
                    if Post.create(post: ActionController::Base.helpers.sanitize(params[:post], tags:  %w(b a i ol ul img li h1 h2 h3, br p), attributes: ['href', 'src']), user_id: decoded[:user_id])
                        render json: {
                            success: true
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

                
            else
                render json: {
                    success: false,
                    message: "invalid_token"
                }
            end
        end
    end

    def encode(payload, exp = 24.hours.from_now)
        payload[:exp] = exp.to_i
        JWT.encode(payload, Rails.application.secrets.secret_key_base)
    end

    def get_json_posts user, friends = nil

        friends = user.friends.where('(sender = ?) or (friendships.accepted = true)', user.id) unless friends

        posts = Post.where("user_id in (#{ friends.map{ |friend| friend.id }.push(user.id).join(',') })")
            .limit(15)
            .order('id desc')
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
            formatted_posts[index][:images] = []

            post.images.each do |image|
                formatted_posts[index][:images].push(image.file.url(:medium))
            end
        end

        formatted_posts

    end

    def fetch_friends
        unless params[:token]
            render json: {
                success: false
            }
        else
            decoded = decode(params[:token])

            if (decoded.is_a?(Hash) && decoded[:user_id])
                # fetch friends
                user = User.find(decoded[:user_id])
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
            else
                render json: {
                    success: false
                }
            end

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

        render json: {
            success: true,
            comments: comments,
            num_comments: comments.length
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
            params.permit(:email, :displayname, :password, :blog_title, :description, :avatar, :theme)
        end
end