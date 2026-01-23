class AddWeightAndGrowthDataToCows < ActiveRecord::Migration[8.0]
  def change
    add_column :cows, :current_weight, :decimal
    add_column :cows, :prev_weight, :decimal
    add_column :cows, :weight_gain, :decimal
    add_column :cows, :avg_daily_gain, :decimal
    add_column :cows, :birth_date, :date
  end
end
