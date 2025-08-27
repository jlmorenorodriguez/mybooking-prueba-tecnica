module Controller
  module Api
    module PricesController

      def self.registered(app)

        #
        # Get all rental locations
        #
        app.get '/api/rental-locations' do
          content_type :json
          
          service = Service::PricesService.new
          use_case = UseCase::Prices::GetRentalLocationsUseCase.new(service, logger)
          result = use_case.perform(params)

          if result.success?
            result.data.to_json
          elsif !result.authorized?
            halt 401
          else
            halt 400, result.message.to_json
          end
        end

        #
        # Get rate types by rental location
        #
        app.get '/api/rental-locations/:rental_location_id/rate-types' do
          content_type :json
          
          service = Service::PricesService.new
          use_case = UseCase::Prices::GetRateTypesByRentalLocationUseCase.new(service, logger)
          result = use_case.perform(params)

          if result.success?
            result.data.to_json
          elsif !result.authorized?
            halt 401
          else
            halt 400, result.message.to_json
          end
        end

        #
        # Get season definitions by rental location and rate type
        #
        app.get '/api/season-definitions' do
          content_type :json
          
          service = Service::PricesService.new
          use_case = UseCase::Prices::GetSeasonDefinitionsUseCase.new(service, logger)
          result = use_case.perform(params)

          if result.success?
            result.data.to_json
          elsif !result.authorized?
            halt 401
          else
            halt 400, result.message.to_json
          end
        end

        #
        # Get seasons by season definition
        #
        app.get '/api/season-definitions/:season_definition_id/seasons' do
          content_type :json
          
          service = Service::PricesService.new
          use_case = UseCase::Prices::GetSeasonsByDefinitionUseCase.new(service, logger)
          result = use_case.perform(params)

          if result.success?
            result.data.to_json
          elsif !result.authorized?
            halt 401
          else
            halt 400, result.message.to_json
          end
        end

        #
        # Get price data for the grid
        #
        app.get '/api/prices' do
          content_type :json
          
          service = Service::PricesService.new
          use_case = UseCase::Prices::GetPricesDataUseCase.new(service, logger)
          result = use_case.perform(params)

          if result.success?
            result.data.to_json
          elsif !result.authorized?
            halt 401
          else
            halt 400, result.message.to_json
          end
        end

        #
        # Import prices from CSV
        #
        app.post '/api/prices/import' do
          content_type :json
          
          begin
            # Check if file was uploaded
            unless params['csv_file'] && params['csv_file'][:tempfile]
              halt 400, { error: "No CSV file provided" }.to_json
            end

            csv_content = params['csv_file'][:tempfile].read
            
            import_service = Service::PriceImportService.new
            use_case = UseCase::Prices::ImportPricesUseCase.new(import_service, logger)
            result = use_case.perform(csv_content)

            if result.success?
              result.data.to_json
            elsif !result.authorized?
              halt 401
            else
              halt 400, result.message.to_json
            end

          rescue => e
            logger.error "Error in import endpoint: #{e.message}"
            halt 500, { error: "Internal server error during import" }.to_json
          end
        end

      end

    end
  end
end