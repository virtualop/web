class Installation < ActiveRecord::Base

  enum status: %i|started base_install installed converting converted deploying deployed finished failed|

end
