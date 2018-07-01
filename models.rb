require "active_record"

class Building < ActiveRecord::Base
  has_many :rooms
end

class Room < ActiveRecord::Base
  belongs_to :building
  has_many :machines
end

class Machine < ActiveRecord::Base
  belongs_to :room
  has_many :usages
end

class User < ActiveRecord::Base
  has_many :usages
end

class Usage < ActiveRecord::Base
  belongs_to :machine
  belongs_to :user
end
