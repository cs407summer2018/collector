require "rubygems"
require 'mysql2'
require "active_record"
require 'net/ssh'

load "models.rb"

keys = YAML::load_file("env.conf")

machine_name = keys["cli"]["machine_name"]
hostname = "#{machine_name}.cs.purdue.edu"
username = keys["cli"]["username"]
password = keys["cli"]["password"]
cmd = "who"

ActiveRecord::Base.
  establish_connection(
    {:adapter => "mysql2",
     :host => keys["db"]["host"],
     :username => keys["db"]["username"],
     :password => keys["db"]["password"],
     :database => keys["db"]["database"]})

# room = Room.all
# puts room.first.capacity
# puts room.first.building
# puts room.first.building.address

# b = Building.new(name: "rex", address: "2813 rex st", abbrev: "WRX")
# b.save
#create == #new -> #save
# puts machine_name
# puts hostname
# puts username


Room.where(room_number: "B148").first.machines.each do |machine|
  hname = "#{machine.name}.cs.purdue.edu"
  Net::SSH.start(hname, username, password: password) do |ssh|
    res = ssh.exec!(cmd)
    if !res.blank?
      puts "$$$$$ #{hname} $$$$$"
      puts res
    end

    ssh.close
  end
end
# b = Building.where(name: "rex").first
# puts b

# Room.create(building: b,
#             room_number: "W76767",
#             capacity: 1,
#             google_calender_id: "meep")
