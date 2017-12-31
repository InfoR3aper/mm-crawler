require 'oj'
require 'pry'

puts 'consolidating...'

json_glob = []
i = 0
Dir.glob('/results/*.json') do |json_file|
  puts i += 1
  next if json_file.include?('profiles.json')
  json_raw = File.read(json_file)
  json = Oj.load(json_raw)
  next if json['error']
  member_id = json['member']['member_id']

  photo_paths = Dir.glob("/results/#{member_id}*.jpg")
  json['photos'] = photo_paths.map { |photo_path| photo_path.gsub('/results', '') }

  json_glob.push(json) if json['photos'].any?
end

File.write('/results/profiles.json', Oj.dump(json_glob))
