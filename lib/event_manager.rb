require 'csv'
require 'google/apis/civicinfo_v2'



# if the zip code is exactly five digits, assume that it is ok
# if the zip code is more than five digits, truncate it to the first five digits
# if the zip code is less than five digits, add zeros to the front until it becomes five digits
def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

# uses google-api to retrieve unique legislators for given zipcode
def legislators_by_zipcode(zipcode)
  # api
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = File.read('secret.key').strip

  # gets representatives by zip
  begin
    legislators = civic_info.representative_info_by_address(
      address: zipcode,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    )
    legislators = legislators.officials
    legislators_names = legislators.map(&:name)
    legislators_names.join(", ")

  # if invalid zip gives website
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

puts "Event Manager Initialized!\n\n"
File.exist?("event_attendees.csv") ? contents = CSV.open('event_attendees.csv', headers: true, header_converters: :symbol) : raise("Terminating program")

contents.each do |row|
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)
  
  puts "#{name} #{zipcode} #{legislators}"
end