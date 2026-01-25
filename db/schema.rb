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

ActiveRecord::Schema[8.0].define(version: 2026_01_24_235820) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "animal_sales", force: :cascade do |t|
    t.bigint "cow_id", null: false
    t.bigint "farm_id", null: false
    t.date "sale_date"
    t.decimal "sale_price"
    t.string "buyer"
    t.string "animal_type"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "buyer_contact"
    t.decimal "weight_at_sale"
    t.index ["cow_id"], name: "index_animal_sales_on_cow_id"
    t.index ["farm_id"], name: "index_animal_sales_on_farm_id"
  end

  create_table "breeding_records", force: :cascade do |t|
    t.bigint "cow_id", null: false
    t.date "breeding_date"
    t.string "bull_name"
    t.string "breeding_method"
    t.date "expected_due_date"
    t.date "actual_due_date"
    t.string "breeding_status"
    t.text "notes"
    t.string "veterinarian"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cow_id"], name: "index_breeding_records_on_cow_id"
  end

  create_table "cows", force: :cascade do |t|
    t.string "name"
    t.string "tag_number"
    t.string "breed"
    t.integer "age"
    t.bigint "farm_id", null: false
    t.string "group_name"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "mother_id"
    t.decimal "current_weight"
    t.decimal "prev_weight"
    t.decimal "weight_gain"
    t.decimal "avg_daily_gain"
    t.date "birth_date"
    t.index ["farm_id", "status"], name: "index_cows_on_farm_id_and_status"
    t.index ["farm_id"], name: "index_cows_on_farm_id"
    t.index ["mother_id"], name: "index_cows_on_mother_id"
    t.index ["tag_number"], name: "index_cows_on_tag_number", unique: true
  end

  create_table "expenses", force: :cascade do |t|
    t.bigint "farm_id", null: false
    t.string "expense_type"
    t.decimal "amount"
    t.text "description"
    t.date "expense_date"
    t.string "category"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["farm_id"], name: "index_expenses_on_farm_id"
  end

  create_table "farms", force: :cascade do |t|
    t.string "name"
    t.string "location"
    t.string "contact_phone"
    t.string "owner"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "cows_count"
    t.integer "active_cows_count", default: 0, null: false
  end

  create_table "health_records", force: :cascade do |t|
    t.bigint "cow_id", null: false
    t.string "health_status"
    t.decimal "temperature"
    t.decimal "weight"
    t.text "notes"
    t.string "recorded_by"
    t.datetime "recorded_at"
    t.string "veterinarian"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cow_id"], name: "index_health_records_on_cow_id"
  end

  create_table "production_records", force: :cascade do |t|
    t.bigint "cow_id", null: false
    t.bigint "farm_id", null: false
    t.date "production_date"
    t.decimal "morning_production"
    t.decimal "noon_production"
    t.decimal "evening_production"
    t.decimal "total_production"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cow_id", "production_date"], name: "index_production_records_on_cow_id_and_production_date"
    t.index ["cow_id"], name: "index_production_records_on_cow_id"
    t.index ["farm_id", "production_date"], name: "index_production_records_on_farm_id_and_production_date"
    t.index ["farm_id"], name: "index_production_records_on_farm_id"
    t.index ["production_date", "cow_id"], name: "index_production_records_on_production_date_and_cow_id"
    t.index ["production_date", "farm_id"], name: "index_production_records_on_production_date_and_farm_id"
    t.index ["production_date", "total_production"], name: "idx_production_records_date_total_desc", order: { total_production: :desc }
    t.index ["production_date"], name: "index_production_records_on_production_date"
    t.index ["total_production"], name: "index_production_records_on_total_production"
  end

  create_table "sales_records", force: :cascade do |t|
    t.bigint "farm_id", null: false
    t.date "sale_date"
    t.decimal "milk_sold"
    t.decimal "cash_sales"
    t.decimal "mpesa_sales"
    t.decimal "total_sales"
    t.string "buyer"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["farm_id", "sale_date"], name: "index_sales_records_on_farm_id_and_sale_date"
    t.index ["farm_id"], name: "index_sales_records_on_farm_id"
    t.index ["sale_date"], name: "index_sales_records_on_sale_date"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "password_digest", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "role", default: "farm_worker"
    t.bigint "farm_id", null: false
    t.boolean "active", default: true
    t.datetime "last_sign_in_at"
    t.string "phone"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["farm_id", "role"], name: "index_users_on_farm_id_and_role"
    t.index ["farm_id"], name: "index_users_on_farm_id"
  end

  create_table "vaccination_records", force: :cascade do |t|
    t.bigint "cow_id", null: false
    t.string "vaccine_name"
    t.date "vaccination_date"
    t.date "next_due_date"
    t.string "administered_by"
    t.string "batch_number"
    t.text "notes"
    t.string "veterinarian"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cow_id"], name: "index_vaccination_records_on_cow_id"
  end

  add_foreign_key "animal_sales", "cows"
  add_foreign_key "animal_sales", "farms"
  add_foreign_key "breeding_records", "cows"
  add_foreign_key "cows", "cows", column: "mother_id"
  add_foreign_key "cows", "farms"
  add_foreign_key "expenses", "farms"
  add_foreign_key "health_records", "cows"
  add_foreign_key "production_records", "cows"
  add_foreign_key "production_records", "farms"
  add_foreign_key "sales_records", "farms"
  add_foreign_key "users", "farms"
  add_foreign_key "vaccination_records", "cows"
end
