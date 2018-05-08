class ApiController < ApplicationController
    protect_from_forgery with: :null_session

    def login
        if (!params[:username] || !params[:password])
            render json: {
                success: false
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
                    username: @user.email,
                    friends: @friends,
                    posts: formatted_posts
                }
            else
                render json: {
                    success: false
                }
            end
        end
    end

    def fetch_posts
        unless (params[:token] && params[:user_id]) 
            render json: {
                success: false
            }
        else
            decoded = decode(params[:token])
            if (decoded[:user_id] && decoded[:user_id].to_i == params[:user_id].to_i)
                # fetch the posts
                user = User.find(decoded[:user_id])
                formatted_posts = get_json_posts(user)

                render json: {
                    success: true,
                    posts: formatted_posts
                }

            else
                render json: {
                    success: false
                }
            end
        end
    end
    def create_post
        # first we need to verify that the user sending the request is authenticated (check their token)
        unless (params[:token] && params[:user_id] && params[:post]) 
            render json: {
                success: false
            }
        else
            # check the token
            decoded = decode(params[:token])

            if (decoded[:user_id] && params[:user_id].to_i == decoded[:user_id].to_i) 
                # the token is valid. create a post for this user.
                @user = User.find(decoded[:user_id])

                if @user
                    if Post.create(post: params[:post], user_id: decoded[:user_id])
                        render json: {
                            success: true
                        }
                    else
                        render json: {
                            success: false
                        }
                    end
                else
                    render json: {
                        success: false
                    }
                end

                
            else
                render json: {
                    success: false
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

    def decode(token)
        body = JWT.decode(token, Rails.application.secrets.secret_key_base)[0]
        HashWithIndifferentAccess.new body
    rescue
        nil
    end
end
