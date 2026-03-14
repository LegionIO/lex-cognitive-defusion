# frozen_string_literal: true

require 'legion/extensions/cognitive_defusion/version'
require 'legion/extensions/cognitive_defusion/helpers/constants'
require 'legion/extensions/cognitive_defusion/helpers/thought'
require 'legion/extensions/cognitive_defusion/helpers/defusion_engine'
require 'legion/extensions/cognitive_defusion/runners/cognitive_defusion'
require 'legion/extensions/cognitive_defusion/client'

module Legion
  module Extensions
    module CognitiveDefusion
      extend Legion::Extensions::Core if Legion::Extensions.const_defined? :Core
    end
  end
end
