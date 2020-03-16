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

ActiveRecord::Schema.define(version: 20200316112741) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "arcs", id: :serial, force: :cascade do |t|
    t.integer "parent_id"
    t.integer "child_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_and", default: true
    t.bigint "identifier"
    t.index ["child_id"], name: "index_arcs_on_child_id"
    t.index ["parent_id", "child_id"], name: "index_arcs_on_parent_id_and_child_id", unique: true
    t.index ["parent_id"], name: "index_arcs_on_parent_id"
  end

  create_table "chatbot_messages", id: :serial, force: :cascade do |t|
    t.string "message", null: false
    t.boolean "is_user_message", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_project_id"
    t.bigint "dialogue_id"
    t.index ["dialogue_id"], name: "index_chatbot_messages_on_dialogue_id"
    t.index ["user_project_id"], name: "index_chatbot_messages_on_user_project_id"
  end

  create_table "conditions", force: :cascade do |t|
    t.integer "option_id"
    t.integer "parameter_id"
    t.integer "arc_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "variable_id", null: false
    t.bigint "identifier"
    t.index ["variable_id"], name: "index_conditions_on_variable_id"
  end

  create_table "connections", force: :cascade do |t|
    t.string "connection_value"
    t.integer "connection_type"
    t.bigint "user_project_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.json "tmp_params"
    t.index ["user_project_id"], name: "index_connections_on_user_project_id"
  end

  create_table "contexts", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "project_id"
    t.bigint "identifier"
    t.string "facebook_persona_id"
    t.index ["project_id"], name: "index_contexts_on_project_id"
  end

  create_table "dialogues", id: :serial, force: :cascade do |t|
    t.integer "context_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "tag"
    t.string "name", null: false
    t.integer "project_id", null: false
    t.json "action"
    t.bigint "identifier"
    t.boolean "form_node", default: false
    t.index ["tag", "project_id"], name: "index_dialogues_on_tag_and_project_id", unique: true
  end

  create_table "intents", force: :cascade do |t|
    t.bigint "dialogue_id", null: false
    t.string "value", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "identifier"
    t.index ["dialogue_id"], name: "index_intents_on_dialogue_id"
  end

  create_table "options", id: :serial, force: :cascade do |t|
    t.integer "variable_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "value"
    t.integer "display_count", default: 1
    t.bigint "identifier"
  end

  create_table "parameters", id: :serial, force: :cascade do |t|
    t.string "value"
    t.float "min"
    t.float "max"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "unit"
    t.bigint "identifier"
    t.bigint "project_id"
    t.index ["project_id"], name: "index_parameters_on_project_id"
  end

  create_table "problems", force: :cascade do |t|
    t.integer "problem_type"
    t.bigint "chatbot_message_id", null: false
    t.bigint "project_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["chatbot_message_id"], name: "index_problems_on_chatbot_message_id"
    t.index ["project_id"], name: "index_problems_on_project_id"
  end

  create_table "projects", id: :serial, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.json "nlp_engine", default: {}, null: false
    t.string "name"
    t.json "external_backend"
    t.boolean "is_private", default: false
    t.json "fallback_setting", default: {"fallback_counter_limit"=>3}
    t.string "facebook_page_id", limit: 20
    t.string "facebook_page_access_token"
    t.integer "version", default: 1
    t.bigint "test_project_id"
    t.index ["facebook_page_id"], name: "index_projects_on_facebook_page_id", unique: true
    t.index ["test_project_id"], name: "index_projects_on_test_project_id"
  end

  create_table "response_contents", id: :serial, force: :cascade do |t|
    t.json "content", null: false
    t.integer "content_type", default: 0, null: false
    t.integer "response_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "identifier"
  end

  create_table "responses", id: :serial, force: :cascade do |t|
    t.integer "response_owner_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "response_owner_type", limit: 20, null: false
    t.integer "order", default: 0, null: false
    t.bigint "identifier"
    t.integer "response_type", default: 0, null: false
    t.index ["response_owner_id", "response_owner_type"], name: "index_responses_on_response_owner_id_and_response_owner_type"
  end

  create_table "user_chatbot_sessions", id: :serial, force: :cascade do |t|
    t.integer "context_id"
    t.integer "dialogue_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "variable_id"
    t.integer "quick_response_id"
    t.integer "fallback_counter"
    t.integer "prev_session_id"
    t.integer "next_session_id"
    t.index ["variable_id"], name: "index_user_chatbot_sessions_on_variable_id"
  end

  create_table "user_data", force: :cascade do |t|
    t.bigint "user_project_id", null: false
    t.bigint "variable_id", null: false
    t.bigint "option_id"
    t.string "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "expired", default: false
    t.index ["option_id"], name: "index_user_data_on_option_id"
    t.index ["user_project_id"], name: "index_user_data_on_user_project_id"
    t.index ["variable_id"], name: "index_user_data_on_variable_id"
  end

  create_table "user_projects", force: :cascade do |t|
    t.integer "role", null: false
    t.bigint "project_id", null: false
    t.bigint "user_id"
    t.bigint "user_chatbot_session_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "send_email", default: false
    t.index ["project_id", "user_id"], name: "index_user_projects_on_project_id_and_user_id", unique: true
    t.index ["project_id"], name: "index_user_projects_on_project_id"
    t.index ["user_chatbot_session_id"], name: "index_user_projects_on_user_chatbot_session_id"
    t.index ["user_id"], name: "index_user_projects_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "provider", default: "email", null: false
    t.string "uid", default: "", null: false
    t.string "encrypted_password", default: ""
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.boolean "allow_password_change", default: false
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.string "name"
    t.string "nickname"
    t.string "image"
    t.string "email"
    t.text "tokens"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["uid", "provider"], name: "index_users_on_uid_and_provider", unique: true
  end

  create_table "variables", id: :serial, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "dialogue_id"
    t.string "possible_values", array: true
    t.integer "expire_after"
    t.integer "storage_type"
    t.integer "source"
    t.boolean "allow_writing", default: true
    t.string "entity"
    t.json "allowed_range"
    t.json "fetch_info"
    t.boolean "save_text", default: false
    t.bigint "project_id"
    t.string "unit"
    t.bigint "identifier"
    t.index ["name", "project_id"], name: "index_variables_on_name_and_project_id", unique: true
    t.index ["project_id"], name: "index_variables_on_project_id"
  end

end
