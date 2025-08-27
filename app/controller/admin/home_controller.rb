module Controller
  module Admin
    module HomeController

      def self.registered(app)

        #
        # Home page - redirect to prices management
        #
        app.get '/' do
          redirect '/prices'
        end

      end
    end
  end
end
