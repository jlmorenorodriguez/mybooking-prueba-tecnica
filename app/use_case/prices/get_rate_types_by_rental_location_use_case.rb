module UseCase
  module Prices
    class GetRateTypesByRentalLocationUseCase

      def initialize(service, logger)
        @service = service
        @logger = logger
      end

      def perform(params)
        begin
          rental_location_id = params['rental_location_id']
          
          if rental_location_id.nil? || rental_location_id.empty?
            return OpenStruct.new(
              success?: false,
              authorized?: true,
              data: nil,
              message: "Rental location ID is required"
            )
          end

          data = @service.get_rate_types_by_rental_location(rental_location_id)
          
          OpenStruct.new(
            success?: true,
            authorized?: true,
            data: data,
            message: nil
          )
        rescue => e
          @logger.error "Error getting rate types by rental location: #{e.message}"
          
          OpenStruct.new(
            success?: false,
            authorized?: true,
            data: nil,
            message: "Error retrieving rate types"
          )
        end
      end

    end
  end
end