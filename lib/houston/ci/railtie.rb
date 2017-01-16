require "houston/ci/commit_ext"
require "houston/ci/project_ext"

module Houston
  module Ci
    class Railtie < ::Rails::Railtie

      # The block you pass to this method will run for every request
      # in development mode, but only once in production.
      config.to_prepare do
        ::Commit.send(:include, Houston::Ci::CommitExt)
        ::Project.send(:include, Houston::Ci::ProjectExt)
      end

    end
  end
end
