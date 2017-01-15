module Houston
  module Ci
    module CommitExt
      extend ActiveSupport::Concern

      included do
        has_one :test_run
      end


      def create_test_run!
        super(project: project, sha: sha, commit: self)
      end

    end
  end
end
