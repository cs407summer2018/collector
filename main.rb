require 'rubygems'
require 'net/ssh'
require 'optparse'
require 'mysql2'
require 'yaml'
require 'time'
require 'date'

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

def get_existing_or_create_user(client, user)
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

  results.first
end

def get_existing_machine(client, name)
  q_string = "SELECT * FROM machine WHERE name = '#{name}';"
  results = client.query(q_string)
  results.first
end

# def get_current_machine_sessions(client, machine_name)
#   machine_rec = get_existing_machine(client, machine_name)
#   machine_id = machine_rec["id"]
#   puts "machine_id"
#   puts machine_id
#   q_string = "SELECT * FROM session WHERE machine_id = #{machine_id} AND end_time IS NULL;"
#   results = client.query(q_string)
#   results
# end

Net::SSH.start(hostname, username, password: password) do |ssh|
  res = ssh.exec!(cmd)
  ssh.close

  machine_record = get_existing_machine(client, machine_name)
  puts machine_record

  # query for current sessions for machine
  # prev_sessions = get_current_machine_sessions(client, machine_name)
  # prev_sessions_match_cur_users = []
  # prev_sessions_not_match_users  = []
  who_data = []

  res.split("\n").each do |line|
    elems = line.split(" ") # skip 5th item?
    date = elems[2]
    time = elems[3]
    datetime = DateTime.parse("#{date} #{time}")
    item = {
      user: elems[0],
      tty: elems[1],
      datetime: datetime
    }
    who_data << item
  end

  user_record = get_existing_or_create_user(client, user)
  puts user_record

  # query for existing session for user/machine/start_time combo
  prev_sessions.each do |sess_record|
    suid = sess_record.user_id
    user_id = user_record.id
    if suid = user_id
      pre_sessions_match_cur_users << thing
    else
      pre_sessions_not_match_users << thing
    end
  end

  if tty.include?("tty")
    # normal login
  end
  if tty.include?("pts")
    # ssh session
    # end
  end
  #  { machine_id: 3, user: james }
  #  { machine_id: 3, user: flynn }

  # user_id matches
  # if same start_time update the record (leave it?)
  # if diff start_time:
  #    mark old as ended
  #    create record for new

  # make it through current users and never matched
  # so not logged in: mark end time as now & update record
end
