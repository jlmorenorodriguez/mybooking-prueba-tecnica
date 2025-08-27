module UseCase
  module Prices
    class GetSeasonDefinitionsUseCase

      def initialize(service, logger)
        @service = service
        @logger = logger
      end

      def perform(params)
        begin
          rental_location_id = params['rental_location_id']
          rate_type_id = params['rate_type_id']
          
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

          data = @service.get_season_definitions(rental_location_id, rate_type_id)
          
          OpenStruct.new(
            success?: true,
            authorized?: true,
            data: data,
            message: nil
          )
        rescue => e
          @logger.error "Error getting season definitions: #{e.message}"
          
          OpenStruct.new(
            success?: false,
            authorized?: true,
            data: nil,
            message: "Error retrieving season definitions"
          )
        end
      end

    end
  end
end