require "houston/adapters/ci_server/github_adapter/job"

module Houston
  module Adapters
    module CIServer
      class GithubAdapter

        def self.errors_with_parameters(project, workflow_file_name)
          {}
        end

        def self.build(project, workflow_file_name)
          Job.new(project, workflow_file_name)
        end

        def self.parameters
          %w{github.workflow_file_name}
        end

      end
    end
  end
end
