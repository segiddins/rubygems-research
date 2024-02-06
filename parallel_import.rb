#!/usr/bin/env ruby -I/Users/segiddins/Development/github.com/ruby/zlib -I/Users/segiddins/Development/github.com/rubygems/rubygems/lib
#!/usr/bin/env sudo rbspy record --format speedscope -- ruby -I/Users/segiddins/Development/github.com/ruby/zlib -I/Users/segiddins/Development/github.com/rubygems/rubygems/lib

puts Gem::VERSION

ENV["RAILS_MAX_THREADS"] = "8"

Dir.chdir "/Users/segiddins/Development/github.com/segiddins/rubygems-research/"

require "./config/environment"

Rails.autoloaders.main.eager_load

#versions = Version.where.not(sha256: nil).where.missing(:quick_spec_blob).includes(:rubygem, :server).order(id: :asc)
#puts "Loading gems for #{versions.count} versions"
#Version.connection.reconnect!

errors = Parallel.map(Version.where.not(sha256: nil).where.missing(:quick_spec_blob).includes(:rubygem, :server, :quick_spec_blob).offset(100).limit(2_000), in_threads: 0, progress: "Importing gem files") do |version|
  next if version.quick_spec_blob
  next unless version.sha256 && version.spec_sha256
  res = Maintenance::ImportGemFileTask.process(version)
  [version.id, res] if res
end
errors.compact!

File.write "/tmp/results.json", JSON.dump(errors)
puts errors.size