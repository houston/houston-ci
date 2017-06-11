module Houston
  module Ci
    module ProjectExt
      extend ActiveSupport::Concern

      included do
        has_many :test_runs, dependent: :destroy
        has_many :tests, dependent: :destroy

        has_adapter :CIServer
      end


      # Continuous Integration
      # ----------------------------------------------------------------------- #

      def ci_server_job_url
        ci_server.job_url
      end

      # ----------------------------------------------------------------------- #


      def create_a_test_run(params)
        unless has_ci_server?
          Rails.logger.warn "[project.create_a_test_run] the project #{name} is not configured to be used with a Continuous Integration server"
          return
        end

        unless params[:sha]
          Rails.logger.error "[project.create_a_test_run] no commit found in payload"
          return
        end

        if params[:sha] == Houston::NULL_GIT_COMMIT
          Rails.logger.error "[project.create_a_test_run] branch was deleted; not running tests again"
          return
        end

        test_run = TestRun.new(params.merge(project: self))

        test_run.notify_of_invalid_configuration do
          test_run.start!
        end

      rescue ActiveRecord::RecordNotUnique
        Rails.logger.warn "[hooks:project:post_receive] a test run exists for #{test_run.short_commit}; doing nothing"
      end


    end
  end
end
