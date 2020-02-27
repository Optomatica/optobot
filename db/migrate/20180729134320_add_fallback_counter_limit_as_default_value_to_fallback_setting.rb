class AddFallbackCounterLimitAsDefaultValueToFallbackSetting < ActiveRecord::Migration[5.1]
  def change
    change_column :projects, :fallback_setting, :json, default: {fallback_counter_limit: 3}
  end
end
