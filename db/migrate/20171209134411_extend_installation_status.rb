class ExtendInstallationStatus < ActiveRecord::Migration
  def change
    Installation.all.each do |installation|
      if installation.status == "deploying"
        installation.status = "finished"
        installation.save!
      end
    end
  end
end
