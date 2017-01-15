require "houston/adapters/ci_server/none_adapter/job"

module Houston
  module Adapters
    module CIServer
      class NoneAdapter

        def self.errors_with_parameters(project)
          {}
        end

        def self.build(project)
          Job.new(project)
        end

        def self.parameters
          []
        end

      end
    end
  end
end
