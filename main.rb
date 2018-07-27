require "rubygems"
require "active_record"
require 'net/ssh'

load "models.rb"

keys = YAML::load_file("env.conf")

@machine_suffix = keys["str"]["machine_suffix"]
@email_suffix   = keys["str"]["email_suffix"]
@username = keys["cli"]["username"]
@password = keys["cli"]["password"]

ActiveRecord::Base.
  establish_connection(
    :adapter  => keys["db"]["adapter"],
     :host     => keys["db"]["host"],
     :username => keys["db"]["username"],
     :password => keys["db"]["password"],
     :database => keys["db"]["database"])

def parse_line_of_cmd_result(line, machine_name)
  data = line.split(" ")
  user = data[0]
  usage = {
    host: machine_name,
    user: user,
    type: data[1],
    datetime: DateTime.parse("#{data[2]} #{data[3]}")
  }
  usage
end

def handle_ssh_output(ssh_output, machine_name)
  machine = Machine.where(name: machine_name).first
  stale_usages = Usage.where(machine: machine, end_time: nil)
  current_usages = {}
  usernames_using_machine = []

  res_lines = ssh_output.split("\n")
  res_lines.each do |line|
    metadata = parse_line_of_cmd_result line, machine_name
    username = metadata[:user]
    usernames_using_machine << username
    begin
      user = User
               .where(name: username, email: "#{username}#{@email_suffix}")
               .first_or_create
      puts "just inserted #{user.inspect}"
      # user.touch(:updated_at)

    rescue => ex
      puts "EXCEPTION"
      puts ex
    end

    begin
      usage = Usage
                .where(user: user, machine: machine,
                       start_time: metadata[:datetime],
                       device: metadata[:type],
                       end_time: nil).first_or_create
      puts "just inserted #{usage.inspect}"
      # usage.touch(:updated_at)

      current_usages[usage[:id]] = usage
    rescue => ex
      puts "EXCEPTION"
      puts ex
    end
  end

  # find all Usages on the machine where where not username


  stale_usages.each do |stale|
    saltine = current_usages[stale.id]
    if !saltine
      stale.update!(end_time: Time.now)
    end
  end
end

def ssh_wrapper(machine_name)
  host_name = "#{machine_name}#{@machine_suffix}"
  puts "Attempting to SSH into #{host_name}"
  begin
    Net::SSH.start(host_name, @username, password: @password) do |ssh|
      res = ssh.exec!("who")
      handle_ssh_output res, machine_name
      ssh.close
    end
  rescue
    puts "Couldn't access #{host_name}"
    machine = Machine.where(name: machine_name).first
    stale_usages = Usage.where(machine: machine, end_time: nil)

    if stale_usages.size > 0
      stale_usages.each do |stale|
        stale.update!(end_time: Time.now)
      end
    end
  end
end

def run_for_machine(machine)
  os = machine.room.specifications.first.OS
  return if os != "Linux"
  ssh_wrapper machine.name
end

def run_by_machine_name(name)
  m = Machine.where(name: name).first
  run_for_machine m
end

def run_by_lab_room_number(room_number)
  r = Room.where(room_number: room_number).first
  r.machines.each do |m|
    run_for_machine m
  end
end

def run_for_all()
  Machine.all.each do |machine|
    run_for_machine machine
  end
end

def room_looper(room)
  start = 0
  finish = 0
  begin
    start = Time.now
    room.machines.each do |machine|
      run_for_machine machine
    end
    finish = Time.now
    diff = finish - start
    puts "*** completed room #{room.room_number} with #{diff} ***"
  end while (finish - start) > 1
end

while true do
  puts "####################"
  puts "### Starting run ###"
  puts "####################"
  run_for_all
end

# def run_par()
#     puts "##### Starting an execution #####"
#     Room.all.each do |room|
#       fork do
#         room_looper room
#       end
#     end
#     Process.waitall
# end

# run_par
