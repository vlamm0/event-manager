require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'



# if the zip code is exactly five digits, assume that it is ok
# if the zip code is more than five digits, truncate it to the first five digits
# if the zip code is less than five digits, add zeros to the front until it becomes five digits
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

def format_time(reg)
  formatted = Time.strptime(reg, "%m/%d/%Y %k:%M")
  [formatted.strftime("%k"), formatted.strftime("%m")]
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

contents.each do |row|
  # name and legislators are used in template binfing
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  phone = clean_phone(row[:homephone])
  legislators = legislators_by_zipcode(zipcode)
  
  #peak hours
  hour, day = format_time(row[:regdate])
  hours[hour].nil? ? hours[hour] = 1 : hours[hour] += 1
  # create personalized html letter and save into output
  #  personal_letter = erb_template.result(binding)
  #  save_thank_you_letter(id, personal_letter)
end

peak_hours = hours.to_a.sort_by {|k, v| v}.last(2).map{|k, v| k}
puts peak_hours