require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'
require 'date'

DAYS = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday]

#  5 digit zip
def clean_zipcode(zipcode)  
  zipcode.to_s.rjust(5, '0')[0..4]
end

# valid 10 digit numbers 
def clean_phone(phone)
  #remove non-nums
  new = phone.to_s.gsub(/[^0-9]/, "")
  new.length == 10 || (new.length == 11 && new[0] == '1') ? new[-10..-1] : 'BAD NUMBER'
end

# uses google-api to retrieve unique legislators for given zipcode
def legislators_by_zipcode(zipcode, civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new)
  # api access
  civic_info.key = File.read('secret.key').strip

  # gets representatives by zip
  begin
    legislators = civic_info.representative_info_by_address(
      address: zipcode,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials 

  # if invalid zip, give website
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

# returns the reg day as an hour and day of the week
def format_time(reg)
  formatted = Time.strptime(reg, "%m/%d/%Y %k:%M")
  date = "20" + formatted.strftime("%Y-%m-%d")
  day = Date.strptime(date).wday
  [formatted.strftime("%k"), DAYS[day]]
end

# adds day or hour to tally-hash
def set_hash(hash, key)
  hash[key].nil? ? hash[key] = 1 : hash[key] += 1
end

# returns 2 keys with the greatest number of occurences
def get_peak_results(hash)
  hash.to_a.sort_by {|k, v| v}.last(2).map{|k, v| k}
end

# saves thank you letters into output folder
def save_thank_you_letter(id, personal_letter)
  Dir.mkdir('output') unless Dir.exist?('output')
  filename = "output/thanks_#{id}.html"
  File.open(filename, "w").puts(personal_letter) 
end


#  main code

puts "Event Manager Initialized!\n\n"
File.exist?("event_attendees.csv") ? contents = CSV.open('event_attendees.csv', headers: true, header_converters: :symbol) : raise("Terminating program")
template_letter = File.read('form_letter.erb')
erb_template = ERB.new(template_letter)
hours = Hash.new()
days = Hash.new()

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  phone = clean_phone(row[:homephone])
  legislators = legislators_by_zipcode(zipcode)
  hour, day = format_time(row[:regdate])
  
  # create a tallyinh hash for hours & days
  set_hash(hours, hour)
  set_hash(days, day)

  # create personalized html letter and save into output
  personal_letter = erb_template.result(binding)
  save_thank_you_letter(id, personal_letter)

end

# get results
peak_hours = get_peak_results(hours)
peak_days = get_peak_results(days)

# display hours
puts "PEAK HOURS\n" 
puts peak_hours
puts "\n\nPEAK DAYS\n"
puts peak_days
