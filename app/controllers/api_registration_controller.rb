class ApiRegistrationController < ApplicationController
    skip_before_action :doorkeeper_authorize!, raise: false
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

    private
        def user_params
            params.permit(:blog_title, :email, :displayname, :password, :description, :avatar, :theme)
        end

end