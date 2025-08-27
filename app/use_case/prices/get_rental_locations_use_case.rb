module UseCase
  module Prices
    class GetRentalLocationsUseCase

      def initialize(service, logger)
        @service = service
        @logger = logger
      end

      def perform(params)
        begin
          data = @service.get_rental_locations
          
          OpenStruct.new(
            success?: true,
            authorized?: true,
            data: data,
            message: nil
          )
        rescue => e
          @logger.error "Error getting rental locations: #{e.message}"
          
          OpenStruct.new(
            success?: false,
            authorized?: true,
            data: nil,
            message: "Error retrieving rental locations"
          )
        end
      end

    end
  end
end