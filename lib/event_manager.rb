require 'csv'
puts "Event Manager Initialized!\n\n"

File.exist?("event_attendees.csv") ? contents = CSV.open('event_attendees.csv', headers: true, header_converters: :symbol) : raise("Terminating program")

contents.each do |row|
  name = row[:first_name]
  zipcode = row[:zipcode]
  puts "#{name} #{zipcode}"
end