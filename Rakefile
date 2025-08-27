require 'rake'

require_relative 'config/application'

task :basic_environment do
  desc "Basic environment"
  Encoding.default_external = Encoding::UTF_8
  Encoding.default_internal = Encoding::UTF_8
end

namespace :foo do
  desc "Foo task"
  task :bar do
    puts "Foo bar"
  end
end

namespace :prices do
  desc "Import prices from CSV file"
  task :import, [:csv_file] => [:basic_environment] do |t, args|
    if args[:csv_file].nil?
      puts "Usage: bundle exec rake prices:import[path/to/file.csv]"
      exit 1
    end

    csv_file = args[:csv_file]
    
    unless File.exist?(csv_file)
      puts "Error: File '#{csv_file}' not found"
      exit 1
    end

    puts "Starting import from #{csv_file}..."
    
    begin
      csv_content = File.read(csv_file)
      import_service = Service::PriceImportService.new
      result = import_service.import_from_csv(csv_content)
      
      puts "\n=== Import Results ==="
      puts "Processed rows: #{result[:processed_rows]}"
      puts "Created prices: #{result[:created_prices]}"
      puts "Updated prices: #{result[:updated_prices]}"
      
      if result[:errors].any?
        puts "\nErrors found:"
        result[:errors].each { |error| puts "  - #{error}" }
        puts "\nImport completed with errors"
      else
        puts "\nImport completed successfully!"
      end
      
    rescue => e
      puts "Error reading file: #{e.message}"
      exit 1
    end
  end
end
