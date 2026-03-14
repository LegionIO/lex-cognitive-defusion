# frozen_string_literal: true

require 'legion/extensions/cognitive_defusion/helpers/constants'
require 'legion/extensions/cognitive_defusion/helpers/thought'
require 'legion/extensions/cognitive_defusion/helpers/defusion_engine'
require 'legion/extensions/cognitive_defusion/runners/cognitive_defusion'

module Legion
  module Extensions
    module CognitiveDefusion
      class Client
        include Runners::CognitiveDefusion

        def initialize(engine: nil)
          @defusion_engine = engine || Helpers::DefusionEngine.new
        end

        private

        attr_reader :defusion_engine
      end
    end
  end
end
