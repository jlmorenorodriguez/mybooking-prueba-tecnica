module Service
  class PricesService

    def get_rental_locations
      sql = <<-SQL
        SELECT DISTINCT rl.id, rl.name
        FROM rental_locations rl
        JOIN category_rental_location_rate_types crlrt ON rl.id = crlrt.rental_location_id
        ORDER BY rl.name;
      SQL

      Infraestructure::Query.run(sql)
    end

    def get_rate_types_by_rental_location(rental_location_id)
      sql = <<-SQL
        SELECT DISTINCT rt.id, rt.name
        FROM rate_types rt
        JOIN category_rental_location_rate_types crlrt ON rt.id = crlrt.rate_type_id
        WHERE crlrt.rental_location_id = ?
        ORDER BY rt.name;
      SQL

      Infraestructure::Query.run(sql, rental_location_id)
    end

    def get_season_definitions(rental_location_id, rate_type_id)
      sql = <<-SQL
        SELECT DISTINCT sd.id, sd.name
        FROM season_definitions sd
        JOIN season_definition_rental_locations sdrl ON sd.id = sdrl.season_definition_id
        JOIN price_definitions pd ON sd.id = pd.season_definition_id
        JOIN category_rental_location_rate_types crlrt ON pd.id = crlrt.price_definition_id
        WHERE crlrt.rental_location_id = ? AND crlrt.rate_type_id = ?
        ORDER BY sd.name;
      SQL

      Infraestructure::Query.run(sql, rental_location_id, rate_type_id)
    end

    def get_seasons_by_definition(season_definition_id)
      sql = <<-SQL
        SELECT s.id, s.name
        FROM seasons s
        WHERE s.season_definition_id = ?
        ORDER BY s.name;
      SQL

      Infraestructure::Query.run(sql, season_definition_id)
    end

    def get_prices_data(rental_location_id, rate_type_id, season_definition_id = nil, season_id = nil, time_measurement = 'days')
      # Convert time_measurement to integer
      time_measurement_int = case time_measurement
                            when 'months' then 1
                            when 'days' then 2
                            when 'hours' then 3
                            when 'minutes' then 4
                            else 2 # default to days
                            end

      # Base query to get categories and their price definitions
      categories_sql = <<-SQL
        SELECT DISTINCT 
               c.id as category_id,
               c.code as category_code, 
               c.name as category_name,
               pd.id as price_definition_id,
               pd.units_management_value_days_list,
               pd.units_management_value_hours_list,
               pd.units_management_value_minutes_list
        FROM categories c
        JOIN category_rental_location_rate_types crlrt ON c.id = crlrt.category_id
        JOIN price_definitions pd ON crlrt.price_definition_id = pd.id
        WHERE crlrt.rental_location_id = ? 
          AND crlrt.rate_type_id = ?
      SQL

      params = [rental_location_id, rate_type_id]

      # Add season filter if provided
      if season_definition_id && !season_definition_id.empty?
        categories_sql += " AND pd.season_definition_id = ?"
        params << season_definition_id
      else
        # If no season definition, get only non-seasonal prices
        categories_sql += " AND pd.season_definition_id IS NULL"
      end

      categories_sql += " ORDER BY c.code;"

      categories = Infraestructure::Query.run(categories_sql, *params)

      # Get the price data for each category
      result = []
      
      categories.each do |category|
        # Get the duration list based on time measurement
        duration_list = case time_measurement
                       when 'days'
                         category['units_management_value_days_list'] || '1'
                       when 'hours'
                         category['units_management_value_hours_list'] || '1'
                       when 'minutes'
                         category['units_management_value_minutes_list'] || '1'
                       else
                         '1'
                       end

        durations = duration_list.split(',').map(&:strip)
        
        # Build price data query
        prices_sql = <<-SQL
          SELECT p.units, p.price
          FROM prices p
          WHERE p.price_definition_id = ?
            AND p.time_measurement = ?
        SQL

        price_params = [category['price_definition_id'], time_measurement_int]

        # Add season filter if provided
        if season_id && !season_id.empty? && season_definition_id && !season_definition_id.empty?
          prices_sql += " AND p.season_id = ?"
          price_params << season_id
        elsif !season_definition_id || season_definition_id.empty?
          # For non-seasonal prices
          prices_sql += " AND p.season_id IS NULL"
        end

        prices = Infraestructure::Query.run(prices_sql, *price_params)
        
        # Create price map
        price_map = {}
        prices.each do |price|
          price_map[price['units']] = price['price']
        end

        # Build category data
        category_data = {
          category_id: category['category_id'],
          category_code: category['category_code'],
          category_name: category['category_name'],
          durations: durations,
          prices: price_map
        }

        result << category_data
      end

      {
        categories: result,
        durations: result.first&.dig(:durations) || ['1']
      }
    end

  end
end