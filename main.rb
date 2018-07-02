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
    {:adapter  => keys["db"]["adapter"],
     :host     => keys["db"]["host"],
     :username => keys["db"]["username"],
     :password => keys["db"]["password"],
     :database => keys["db"]["database"]})

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

  ssh_output.split("\n").each do |line|
    metadata = parse_line_of_cmd_result line, machine_name
    username = metadata[:user]
    user = User
             .where(name: username, email: "#{username}#{@email_suffix}")
             .first_or_create

    usage = Usage
              .where(user: user, machine: machine,
                     start_time: metadata[:datetime],
                     device: metadata[:type])
              .first_or_create
    current_usages[usage[:id]] = usage
  end

  puts "***** on #{machine_name} with machine_id #{machine.id} *****"

  stale_usages.each do |stale|
    matched = current_usages[stale.id]
    stale.update!(end_time: Time.now) if !matched
  end

end

def ssh_wrapper(machine_name)
  host_name = "#{machine_name}#{@machine_suffix}"
  puts "Attempting to SSH into #{host_name}"
  Net::SSH.start(host_name, @username, password: @password) do |ssh|
    res = ssh.exec!("who")
    handle_ssh_output res, machine_name
    ssh.close
  end
end

def run_for_machine(machine)
  os = machine.room.specifications.first.OS
  return if os != "Linux"
  ssh_wrapper machine.name
end

Machine.all.each do |machine|
  run_for_machine machine
end

# m = Machine.where(name: "borg20").first
# run_for_machine m
