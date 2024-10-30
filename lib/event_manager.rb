puts "Event Manager Initialized!\n\n"

File.exist?("event_attendees.csv") ? lines = File.readlines('event_attendees.csv') : raise("Terminating program")

lines.each_with_index do |line, index|
  next if index == 0
  col = line.split(",")
  name = col[2]
  puts name
end