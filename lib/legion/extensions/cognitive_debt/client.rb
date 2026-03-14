# frozen_string_literal: true

require 'legion/extensions/cognitive_debt/helpers/constants'
require 'legion/extensions/cognitive_debt/helpers/debt_item'
require 'legion/extensions/cognitive_debt/helpers/debt_engine'
require 'legion/extensions/cognitive_debt/runners/cognitive_debt'

module Legion
  module Extensions
    module CognitiveDebt
      class Client
        include Runners::CognitiveDebt

        def initialize(engine: nil, **)
          @default_engine = engine || Helpers::DebtEngine.new
        end

        private

        attr_reader :default_engine
      end
    end
  end
end
