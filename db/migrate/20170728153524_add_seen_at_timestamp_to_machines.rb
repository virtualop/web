class AddSeenAtTimestampToMachines < ActiveRecord::Migration
  def change
    add_column :machines, :seen_at, :datetime
  end
end
