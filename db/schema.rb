# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20180624234425) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "comments", id: :serial, force: :cascade do |t|
    t.text "comment"
    t.integer "parent"
    t.integer "user_id"
    t.integer "post_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["post_id"], name: "index_comments_on_post_id"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "friendships", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "friend_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "accepted"
    t.integer "sender"
    t.index ["user_id"], name: "index_friendships_on_user_id"
  end

  create_table "images", id: :serial, force: :cascade do |t|
    t.integer "post_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "file_file_name", limit: 255
    t.string "file_content_type", limit: 255
    t.integer "file_file_size"
    t.datetime "file_updated_at"
    t.index ["post_id"], name: "index_images_on_post_id"
  end

  create_table "post_tags", id: :serial, force: :cascade do |t|
    t.integer "post_id"
    t.integer "tag_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["post_id"], name: "index_post_tags_on_post_id"
    t.index ["tag_id"], name: "index_post_tags_on_tag_id"
  end

  create_table "posts", id: :serial, force: :cascade do |t|
    t.text "post"
    t.integer "edited"
    t.integer "num_comments", default: 0
    t.integer "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "tags", limit: 255
    t.integer "security_level"
    t.integer "source"
    t.index ["user_id"], name: "index_posts_on_user_id"
  end

  create_table "tags", id: :serial, force: :cascade do |t|
    t.string "tag_name", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["tag_name"], name: "index_tags_on_tag_name", unique: true
  end

  create_table "themes", id: :serial, force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "theme_name", limit: 255
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "email", limit: 255
    t.string "displayname", limit: 255
    t.string "blog_title", limit: 255
    t.string "description", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "password_digest", limit: 255
    t.string "avatar_file_name", limit: 255
    t.string "avatar_content_type", limit: 255
    t.integer "avatar_file_size"
    t.datetime "avatar_updated_at"
    t.string "reset_password_token", limit: 255
    t.datetime "reset_password_sent_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet "current_sign_in_ip"
    t.inet "last_sign_in_ip"
    t.string "confirmation_token", limit: 255
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email", limit: 255
    t.integer "theme_id"
    t.string "text_color"
    t.string "background_color"
    t.string "banner_file_name"
    t.string "banner_content_type"
    t.integer "banner_file_size"
    t.datetime "banner_updated_at"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["displayname"], name: "index_users_on_displayname", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["theme_id"], name: "index_users_on_theme_id"
  end

end
