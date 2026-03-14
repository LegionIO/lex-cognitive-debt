# frozen_string_literal: true

require 'legion/extensions/cognitive_debt/version'
require 'legion/extensions/cognitive_debt/helpers/constants'
require 'legion/extensions/cognitive_debt/helpers/debt_item'
require 'legion/extensions/cognitive_debt/helpers/debt_engine'
require 'legion/extensions/cognitive_debt/runners/cognitive_debt'

module Legion
  module Extensions
    module CognitiveDebt
      extend Legion::Extensions::Core if Legion::Extensions.const_defined? :Core
    end
  end
end
