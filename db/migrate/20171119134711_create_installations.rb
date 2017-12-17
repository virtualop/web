class CreateInstallations < ActiveRecord::Migration
  def change
    create_table :installations do |t|
      t.string :host_name
      t.string :vm_name
      t.integer :status, default: 0

      t.timestamps null: false
    end
    add_index :installations, [ :host_name, :vm_name ], unique: true
  end
end
