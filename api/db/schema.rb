# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2025_09_23_130102) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "contracts", force: :cascade do |t|
    t.string "contract_type"
    t.string "provider"
    t.string "category"
    t.string "plan_name"
    t.string "contract_number"
    t.string "customer_number"
    t.string "msisdn"
    t.date "start_date"
    t.date "end_date"
    t.integer "min_term_months"
    t.integer "notice_period_days"
    t.decimal "monthly_fee"
    t.decimal "promo_monthly_fee"
    t.date "promo_end_date"
    t.string "currency"
    t.string "termination_email"
    t.string "termination_address"
    t.text "notes"
    t.bigint "person_id", null: false
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "country_code", default: "DE", null: false
    t.index ["contract_type"], name: "index_contracts_on_contract_type"
    t.index ["country_code"], name: "index_contracts_on_country_code"
    t.index ["discarded_at"], name: "index_contracts_on_discarded_at"
    t.index ["person_id"], name: "index_contracts_on_person_id"
    t.check_constraint "contract_type::text = ANY (ARRAY['mobile'::character varying, 'gym'::character varying, 'insurance'::character varying]::text[])", name: "contracts_contract_type_check"
  end

  create_table "documents", force: :cascade do |t|
    t.bigint "contract_id", null: false
    t.string "title"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "sha256"
    t.string "content_type"
    t.bigint "size_bytes"
    t.string "status", default: "pending", null: false
    t.string "parser_name"
    t.datetime "parsed_at"
    t.text "parse_error"
    t.bigint "uploaded_by_id"
    t.string "country_code"
    t.index ["contract_id"], name: "index_documents_on_contract_id"
    t.index ["country_code"], name: "index_documents_on_country_code"
    t.index ["sha256"], name: "index_documents_on_sha256", unique: true
    t.index ["status"], name: "index_documents_on_status"
    t.index ["uploaded_by_id"], name: "index_documents_on_uploaded_by_id"
  end

  create_table "expenses", force: :cascade do |t|
    t.bigint "contract_id", null: false
    t.string "name"
    t.string "expense_type"
    t.decimal "amount"
    t.string "currency"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["contract_id"], name: "index_expenses_on_contract_id"
  end

  create_table "people", force: :cascade do |t|
    t.string "name"
    t.date "dob"
    t.string "relation"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
  end

  create_table "reminders", force: :cascade do |t|
    t.bigint "contract_id", null: false
    t.string "title"
    t.text "notes"
    t.datetime "due_at"
    t.integer "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["contract_id"], name: "index_reminders_on_contract_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "contracts", "people"
  add_foreign_key "documents", "contracts"
  add_foreign_key "documents", "users", column: "uploaded_by_id"
  add_foreign_key "expenses", "contracts"
  add_foreign_key "reminders", "contracts"
end
