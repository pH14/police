module Police
  module Controller
    extend ActiveSupport::Concern

    included do
      before_action :set_user
    end

    def set_user
      puts "Controller setting the user! Set to #{current_user}"
      request.env['police.set_user'].call current_user
    end
  end
end
