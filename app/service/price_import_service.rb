require 'csv'

module Service
  class PriceImportService

    def initialize
      @processed_rows = 0
      @created_prices = 0
      @updated_prices = 0
      @errors = []
    end

    def import_from_csv(csv_content)
      begin
        csv_data = CSV.parse(csv_content, headers: true)
        
        csv_data.each_with_index do |row, index|
          process_row(row, index + 2) # +2 because CSV is 1-indexed and we have headers
        end

        {
          success: @errors.empty?,
          processed_rows: @processed_rows,
          created_prices: @created_prices,
          updated_prices: @updated_prices,
          errors: @errors
        }

      rescue CSV::MalformedCSVError => e
        {
          success: false,
          processed_rows: 0,
          created_prices: 0,
          updated_prices: 0,
          errors: ["CSV malformed: #{e.message}"]
        }
      rescue => e
        {
          success: false,
          processed_rows: 0,
          created_prices: 0,
          updated_prices: 0,
          errors: ["Unexpected error: #{e.message}"]
        }
      end
    end

    private

    def process_row(row, row_number)
      @processed_rows += 1

      # Extract basic data
      rental_location_name = row['rental_location_name']&.strip
      rate_type_name = row['rate_type_name']&.strip
      season_definition_name = row['season_definition_name']&.strip
      season_name = row['season_name']&.strip
      category_code = row['category_code']&.strip

      # Validate required fields
      if rental_location_name.nil? || rental_location_name.empty?
        @errors << "Row #{row_number}: rental_location_name is required"
        return
      end

      if rate_type_name.nil? || rate_type_name.empty?
        @errors << "Row #{row_number}: rate_type_name is required"
        return
      end

      if category_code.nil? || category_code.empty?
        @errors << "Row #{row_number}: category_code is required"
        return
      end

      # Find entities
      rental_location = find_rental_location_by_name(rental_location_name)
      unless rental_location
        @errors << "Row #{row_number}: Rental location '#{rental_location_name}' not found"
        return
      end

      rate_type = find_rate_type_by_name(rate_type_name)
      unless rate_type
        @errors << "Row #{row_number}: Rate type '#{rate_type_name}' not found"
        return
      end

      category = find_category_by_code(category_code)
      unless category
        @errors << "Row #{row_number}: Category '#{category_code}' not found"
        return
      end

      # Find season definition and season (optional)
      season_definition = nil
      season = nil

      if season_definition_name && !season_definition_name.empty?
        season_definition = find_season_definition_by_name(season_definition_name)
        unless season_definition
          @errors << "Row #{row_number}: Season definition '#{season_definition_name}' not found"
          return
        end

        if season_name && !season_name.empty?
          season = find_season_by_name(season_name, season_definition['id'])
          unless season
            @errors << "Row #{row_number}: Season '#{season_name}' not found in definition '#{season_definition_name}'"
            return
          end
        end
      end

      # Find price definition
      price_definition = find_price_definition(
        rental_location['id'], 
        rate_type['id'], 
        category['id'],
        season_definition&.dig('id')
      )

      unless price_definition
        @errors << "Row #{row_number}: No price definition found for this combination"
        return
      end

      # Get valid duration columns for this price definition
      valid_durations = get_valid_durations(price_definition)
      
      # Process price columns
      row.headers.each do |header|
        next unless header.match?(/^\d+$/) # Only numeric headers (duration columns)
        
        duration = header.to_i
        price_value = row[header]
        
        # Skip empty prices
        next if price_value.nil? || price_value.strip.empty?

        # Validate that this duration is allowed for this price definition
        unless valid_durations.include?(duration)
          @errors << "Row #{row_number}: Duration '#{duration}' not allowed for this price definition (allowed: #{valid_durations.join(', ')})"
          next
        end

        # Parse price
        begin
          price = Float(price_value.strip)
        rescue ArgumentError
          @errors << "Row #{row_number}: Invalid price value '#{price_value}' for duration #{duration}"
          next
        end

        # Create or update price
        create_or_update_price(
          price_definition['id'],
          season&.dig('id'),
          duration,
          price,
          row_number
        )
      end

    rescue => e
      @errors << "Row #{row_number}: Unexpected error - #{e.message}"
    end

    def find_rental_location_by_name(name)
      sql = "SELECT id, name FROM rental_locations WHERE name = ?"
      results = Infraestructure::Query.run(sql, name)
      results.first
    end

    def find_rate_type_by_name(name)
      sql = "SELECT id, name FROM rate_types WHERE name = ?"
      results = Infraestructure::Query.run(sql, name)
      results.first
    end

    def find_category_by_code(code)
      sql = "SELECT id, code, name FROM categories WHERE code = ?"
      results = Infraestructure::Query.run(sql, code)
      results.first
    end

    def find_season_definition_by_name(name)
      sql = "SELECT id, name FROM season_definitions WHERE name = ?"
      results = Infraestructure::Query.run(sql, name)
      results.first
    end

    def find_season_by_name(name, season_definition_id)
      sql = "SELECT id, name FROM seasons WHERE name = ? AND season_definition_id = ?"
      results = Infraestructure::Query.run(sql, name, season_definition_id)
      results.first
    end

    def find_price_definition(rental_location_id, rate_type_id, category_id, season_definition_id)
      if season_definition_id
        sql = <<-SQL
          SELECT pd.*
          FROM price_definitions pd
          JOIN category_rental_location_rate_types crlrt ON pd.id = crlrt.price_definition_id
          WHERE crlrt.rental_location_id = ? 
            AND crlrt.rate_type_id = ? 
            AND crlrt.category_id = ?
            AND pd.season_definition_id = ?
        SQL
        results = Infraestructure::Query.run(sql, rental_location_id, rate_type_id, category_id, season_definition_id)
      else
        sql = <<-SQL
          SELECT pd.*
          FROM price_definitions pd
          JOIN category_rental_location_rate_types crlrt ON pd.id = crlrt.price_definition_id
          WHERE crlrt.rental_location_id = ? 
            AND crlrt.rate_type_id = ? 
            AND crlrt.category_id = ?
            AND pd.season_definition_id IS NULL
        SQL
        results = Infraestructure::Query.run(sql, rental_location_id, rate_type_id, category_id)
      end
      
      results.first
    end

    def get_valid_durations(price_definition)
      # Default to days measurement (2)
      time_measurement = price_definition['time_measurement_days'] ? 'days' : 
                        price_definition['time_measurement_hours'] ? 'hours' :
                        price_definition['time_measurement_minutes'] ? 'minutes' :
                        price_definition['time_measurement_months'] ? 'months' : 'days'

      duration_list = case time_measurement
                     when 'days'
                       price_definition['units_management_value_days_list'] || '1'
                     when 'hours'
                       price_definition['units_management_value_hours_list'] || '1'
                     when 'minutes'
                       price_definition['units_management_value_minutes_list'] || '1'
                     when 'months'
                       '1' # Default for months
                     else
                       '1'
                     end

      duration_list.split(',').map(&:strip).map(&:to_i)
    end

    def create_or_update_price(price_definition_id, season_id, duration, price, row_number)
      # Ensure all parameters are the correct type
      price_definition_id = price_definition_id.to_i
      season_id = season_id.to_i if season_id
      duration = duration.to_i
      price = price.to_f
      
      # Check if price exists using DataMapper
      if season_id
        existing_price = Model::Price.first(
          price_definition_id: price_definition_id,
          season_id: season_id,
          units: duration,
          time_measurement: :days
        )
      else
        existing_price = Model::Price.first(
          price_definition_id: price_definition_id,
          season_id: nil,
          units: duration,
          time_measurement: :days
        )
      end

      if existing_price.nil?
        # Create new price using DataMapper model
        price_obj = Model::Price.new
        price_obj.price_definition_id = price_definition_id
        price_obj.season_id = season_id if season_id
        price_obj.units = duration
        price_obj.time_measurement = :days # Default to days
        price_obj.price = price
        
        if price_obj.save
          @created_prices += 1
        else
          @errors << "Row #{row_number}: Could not save price for duration #{duration} - #{price_obj.errors.full_messages.join(', ')}"
        end
      else
        # Update existing price using DataMapper
        existing_price.price = price
        if existing_price.save
          @updated_prices += 1
        else
          @errors << "Row #{row_number}: Could not update price for duration #{duration} - #{existing_price.errors.full_messages.join(', ')}"
        end
      end

    rescue => e
      @errors << "Row #{row_number}: Error saving price for duration #{duration} - #{e.message}"
    end

  end
end