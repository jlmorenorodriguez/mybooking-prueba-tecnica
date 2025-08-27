module UseCase
  module Prices
    class GetPricesDataUseCase

      def initialize(service, logger)
        @service = service
        @logger = logger
      end

      def perform(params)
        begin
          rental_location_id = params['rental_location_id']
          rate_type_id = params['rate_type_id']
          season_definition_id = params['season_definition_id']
          season_id = params['season_id']
          time_measurement = params['time_measurement'] || 'days'
          
          if rental_location_id.nil? || rental_location_id.empty?
            return OpenStruct.new(
              success?: false,
              authorized?: true,
              data: nil,
              message: "Rental location ID is required"
            )
          end

          if rate_type_id.nil? || rate_type_id.empty?
            return OpenStruct.new(
              success?: false,
              authorized?: true,
              data: nil,
              message: "Rate type ID is required"
            )
          end

          data = @service.get_prices_data(
            rental_location_id, 
            rate_type_id, 
            season_definition_id, 
            season_id, 
            time_measurement
          )
          
          OpenStruct.new(
            success?: true,
            authorized?: true,
            data: data,
            message: nil
          )
        rescue => e
          @logger.error "Error getting prices data: #{e.message}"
          
          OpenStruct.new(
            success?: false,
            authorized?: true,
            data: nil,
            message: "Error retrieving prices data"
          )
        end
      end

    end
  end
end