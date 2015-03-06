module Police
  module Middleware
    include Rack
    include ActionView

    def initialize(app)
      @app = app
    end

    def label_hash(h, label)
      h.each do |k, v|
        if v.is_a? Hash
          puts "Rack: labeling a hash #{h}"
          v = label_hash v, label
        else
          puts "Rack: labeling value #{v}"
          v.label_with label
        end
      end

      h
    end

    def call(env)
      user_supplied_label = Police::DataFlow::UserSupplied.new

      req = Rack::Request.new(env)

      puts "Request params #{req.params}"

      req.params.each do |k, v|
        if v.is_a? Hash
          puts "Rack: labeling a hash #{v} start"
          v = label_hash(v, user_supplied_label)
          req.update_param k, v
        else
          puts "Rack: labeling #{k}'s value #{v}"
          req.update_param k, v.label_with(user_supplied_label)
        end
      end

      ['QUERY_STRING', 'REQUEST_URI', 'ORIGINAL_FULLPATH', 'rack.request.query_string', 'rack.request.form_vars'].each do |user_supplied_data|
        puts "Labeling env param #{user_supplied_data}, #{env[user_supplied_data]}"
        env[user_supplied_label].label_with user_supplied_label
      end

      # ['rack.request.form_hash', 'rack.request.query_hash'].each do |user_supplied_data|
      #   puts "Labeling env hash #{user_supplied_data}, #{env[user_supplied_data]}"
      #   label_hash env[user_supplied_data], user_supplied_label if env[user_supplied_data]
      # end

      env['police.from_user_label'] = user_supplied_label

      env['police.set_user'] = lambda do |user|
        user_supplied_label.payload = user
      end

      status, headers, response = @app.call(env)

      if response.is_a? Rack::BodyProxy
        response.each do |v|
          puts "Checking dataflow on output. Output has #{v.labels.size} labels"

          v.labels.each do |label|
            case label
            when Police::DataFlow::ReadRestriction
              puts "Have a read restriction"
              origin = label.payload
              origin.enforce_read_restrictions env['police.from_user_label'].payload
              # Figure out santization rules so that this doesn't always propagate
              # when Police::DataFlow::UserSupplied
              #   raise Police::PoliceError, "unsanitized user supplied string at output"
            end
          end
        end
      end

      # puts "Status is #{status}, Headers are #{headers}, #{headers.tainted?}"
      return status, headers, response
    end
  end
end