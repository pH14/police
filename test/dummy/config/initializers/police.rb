# class PoliceMiddleware
#     include Rack
#     include ActionView
#     require 'pp'

#     def initialize(app)
#         @app = app
#     end

#     def call(env)
#         puts env
#         return @app.call env

#         status, headers, response = @app.call(env)
#         # puts "Status is #{status}, Headers are #{headers}, #{headers.tainted?}"

#         return status, headers, response
#     end
# end

# Rails.application.config.middleware.use PoliceMiddleware