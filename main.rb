require 'rubygems'
require 'net/ssh'
require 'optparse'
require 'mysql2'
require 'yaml'

keys = YAML::load_file("env.conf")

client = Mysql2::Client.new(
  :host => keys["db"]["host"],
  :username => keys["db"]["username"],
  :password => keys["db"]["password"],
  :database => keys["db"]["database"]
)

machine_name = keys["cli"]["machine_name"]
hostname = "#{machine_name}.cs.purdue.edu"
username = keys["cli"]["username"]
password = keys["cli"]["password"]
cmd = "who"

def get_existing_or_create_user(user)
  q_string = "SELECT * FROM user WHERE name = '#{user}';"
  results = client.query(q_string)

  if results.size == 0
    # insert the user in the database
    i_string = "INSERT INTO user ( name, email ) VALUES ( \"#{user}\", \"#{user}@purdue.edu\" ) ;"
    puts i_string
    client.query(i_string)
  end

  q_string = "SELECT * FROM user WHERE name = '#{user}';"
  results = client.query(q_string)

  results[0]
end

def get_existing_machine(name)
  q_string = "SELECT * FROM machine WHERE name = '#{name}';"
  results = client.query(q_string)
  results[0]
end

Net::SSH.start(hostname, username, password: password) do |ssh|
  res = ssh.exec!(cmd)
  ssh.close

  res.split("\n").each do |line|
    puts "#########"
    elems = line.split(" ") # skip 5th item?
    user = elems[0]
    tty  = elems[1]
    date = elems[2]
    time = elems[3]

    puts "user: "+user
    puts "tty: "+tty
    # puts "date: "+date
    # puts "time: "+time

    user_record = get_existing_or_create_user(user)
    machine_record = get_existing_machine(machine_name)

    if tty.include?("tty")
      # normal login
    end
    if tty.include?("pts")
      # ssh session
    end
  end

end
