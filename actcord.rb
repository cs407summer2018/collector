require "rubygems"
require 'mysql2'
require "active_record"
require 'net/ssh'

load "models.rb"

keys = YAML::load_file("env.conf")

@machine_suffix = ".cs.purdue.edu"
@email_suffix = "@purdue.edu"
# machine_name = keys["cli"]["machine_name"]
@username = keys["cli"]["username"]
@password = keys["cli"]["password"]
@cmd = "who"

ActiveRecord::Base.
  establish_connection(
    {:adapter => "mysql2",
     :host => keys["db"]["host"],
     :username => keys["db"]["username"],
     :password => keys["db"]["password"],
     :database => keys["db"]["database"]})

#create == #new -> #save
puts Machine.count

def run_for_machine(machine)

  hostname = "#{machine.name}#{@machine_suffix}"
  os = machine.room.specifications.first.OS
  return if os != "Linux"
  puts "Attempting to SSH into #{hostname}"
  Net::SSH.start(hostname, @username, password: @password) do |ssh|
    res = ssh.exec!(@cmd)
    if !res.blank? # machine has users
      res.split("\n").each do |line|
        data = line.split(" ")
        user = data[0]
        usage = {
          host: machine.name,
          user: user,
          type: data[1],
          datetime: DateTime.parse("#{data[2]} #{data[3]}")
        }
        User.where(name: user, email: "#{user}#{@email_suffix}").first_or_create
        puts usage
      end
    end
    ssh.close
  end

end

# Machine.all.each_slice(30).to_a.each do |chunk_of_machines|
#   Process.fork do
#     chunk_of_machines.each do |machine|
#       run_for_machine machine
#     end
#   end
#   Process.wait
# end

Machine.all.each do |machine|
  run_for_machine machine
end

# $ ssh suterr@xinu22.cs.purdue.edu
# $ ssh suterr@xinu23.cs.purdue.edu
# $ ssh suterr@xinu24.cs.purdue.edu
# ssh: Could not resolve hostname xinu22.cs.purdue.edu: nodename nor servname provided, or not known
# $ ssh suterr@pod4-5.cs.purdue.edu
# ssh: connect to host pod4-5.cs.purdue.edu port 22: Network is unreachable

# Machine.all.each do |machine|
#   hostname = "#{machine.name}#{@machine_suffix}"
#   os = machine.room.specifications.first.OS
#   next if os != "Linux"
#   Net::SSH.start(hostname, username, password: password) do |ssh|
#     res = ssh.exec!(cmd)
#     if !res.blank? # machine has users
#       res.split("\n").each do |line|
#         data = line.split(" ")
#         user = data[0]
#         usage = {
#           host: machine.name,
#           user: user,
#           type: data[1],
#           datetime: DateTime.parse("#{data[2]} #{data[3]}")
#         }
#         # User.where(name: user, email: "#{user}#{@email_suffix}").first_or_create
#         puts usage
#       end
#     end
#     ssh.close
#   end
# end

# Room.where(room_number: "B148").first.machines.each do |machine|

#   Net::SSH.start("#{machine.name}#{@machine_suffix}", username, password: password) do |ssh|

#     res = ssh.exec!(cmd)
#     if !res.blank? # machine has users
#       res.split("\n").each do |line|
#         data = line.split(" ")
#         user = data[0]
#         usage = {
#           host: machine.name,
#           user: user,
#           type: data[1],
#           datetime: DateTime.parse("#{data[2]} #{data[3]}")
#         }

#         User.where(name: user, email: "#{user}#{@email_suffix}").first_or_create
#         puts usage
#       end
#     end

#     ssh.close
#   end
# end
