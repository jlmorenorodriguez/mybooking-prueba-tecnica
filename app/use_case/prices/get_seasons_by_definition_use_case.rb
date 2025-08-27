module UseCase
  module Prices
    class GetSeasonsByDefinitionUseCase

      def initialize(service, logger)
        @service = service
        @logger = logger
      end

      def perform(params)
        begin
          season_definition_id = params['season_definition_id']
          
          if season_definition_id.nil? || season_definition_id.empty?
            return OpenStruct.new(
              success?: false,
              authorized?: true,
              data: nil,
              message: "Season definition ID is required"
            )
          end

          data = @service.get_seasons_by_definition(season_definition_id)
          
          OpenStruct.new(
            success?: true,
            authorized?: true,
            data: data,
            message: nil
          )
        rescue => e
          @logger.error "Error getting seasons by definition: #{e.message}"
          
          OpenStruct.new(
            success?: false,
            authorized?: true,
            data: nil,
            message: "Error retrieving seasons"
          )
        end
      end

    end
  end
end