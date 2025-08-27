module Controller
  module PricesPageController

    def self.registered(app)

      #
      # Prices management page
      #
      app.get '/prices' do
        erb :prices
      end

      #
      # Sample CSV download
      #
      app.get '/sample_import.csv' do
        content_type 'text/csv'
        attachment 'sample_import.csv'
        
        csv_path = File.join(File.dirname(__FILE__), '..', '..', 'sample_import.csv')
        if File.exist?(csv_path)
          File.read(csv_path)
        else
          halt 404, "Sample CSV file not found"
        end
      end

    end

  end
end