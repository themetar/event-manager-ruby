require 'csv'
require 'bundler/setup'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def legislators_by_zipcode(zipcode)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zipcode,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials 
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exists?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def generate_emails(contents)
  template_letter = File.read('form_letter.erb')
  erb_template = ERB.new template_letter
  
  contents.each do |row|
    id = row[0]
    name = row[:first_name]
  
    zipcode = clean_zipcode(row[:zipcode])
  
    legislators = legislators_by_zipcode(zipcode)
  
    form_letter = erb_template.result(binding)
  
    save_thank_you_letter(id, form_letter)  
  end
end

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

command  = ARGV[0]

puts 'Event Manager Initialized!' if ['emails'].include?(command)

case command
when 'emails'
  require 'erb'
  require 'google/apis/civicinfo_v2'
  generate_emails(contents)  
else
  puts %$Usage: ruby lib/event_manager.rb COMMAND

COMMANDS:

  emails    Generates call to action emails in oputput directory.$
end


