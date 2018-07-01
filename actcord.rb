require "rubygems"
require 'mysql2'
require "active_record"
require 'net/ssh'

load "models.rb"

keys = YAML::load_file("env.conf")

@machine_suffix = ".cs.purdue.edu"
@email_suffix   = "@purdue.edu"
@username = keys["cli"]["username"]
@password = keys["cli"]["password"]
@cmd      = "who"

ActiveRecord::Base.
  establish_connection(
    {:adapter => "mysql2",
     :host => keys["db"]["host"],
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
  User.where(name: user, email: "#{user}#{@email_suffix}").first_or_create
  usage
end

def handle_ssh_output(res, machine_name)
  return if res.blank? # machine has no users
  usages = []
  res.split("\n").each do |line|
    usage = parse_line_of_cmd_result line, machine_name
    usages << usage
    puts usage
  end
  # TODO: Update or insert usage record as necessary
end

def ssh_wrapper(machine_name)
  host_name = "#{machine_name}#{@machine_suffix}"
  puts "Attempting to SSH into #{host_name}"
  Net::SSH.start(host_name, @username, password: @password) do |ssh|
    res = ssh.exec!(@cmd)
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
