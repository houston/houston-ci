module Houston
  module Adapters
    module CIServer
      class NoneAdapter
        class Job

          def initialize(project)
          end

          def job_url
            nil
          end

          def build!(commit)
          end
          alias retry! build!

          def fetch_results!(results_url)
            {}
          end

        end
      end
    end
  end
end
