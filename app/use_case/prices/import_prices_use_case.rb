module UseCase
  module Prices
    class ImportPricesUseCase

      def initialize(service, logger)
        @service = service
        @logger = logger
      end

      def perform(csv_content)
        begin
          if csv_content.nil? || csv_content.empty?
            return OpenStruct.new(
              success?: false,
              authorized?: true,
              data: nil,
              message: "CSV content is empty"
            )
          end

          result = @service.import_from_csv(csv_content)
          
          if result[:success]
            @logger.info "Import completed successfully: #{result[:processed_rows]} rows processed, #{result[:created_prices]} created, #{result[:updated_prices]} updated"
          else
            @logger.warn "Import completed with errors: #{result[:errors].join(', ')}"
          end
          
          OpenStruct.new(
            success?: true,
            authorized?: true,
            data: result,
            message: nil
          )
        rescue => e
          @logger.error "Error in import use case: #{e.message}"
          
          OpenStruct.new(
            success?: false,
            authorized?: true,
            data: nil,
            message: "Error during import process"
          )
        end
      end

    end
  end
end