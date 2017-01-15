require "houston/ci/engine"
require "houston/ci/configuration"

module Houston
  module Ci
    extend self

    def config(&block)
      @configuration ||= Ci::Configuration.new
      @configuration.instance_eval(&block) if block_given?
      @configuration
    end

  end


  # Extension Points
  # ===========================================================================
  #
  # Read more about extending Houston at:
  # https://github.com/houston/houston-core/wiki/Modules


  # Register events that will be raised by this module

   register_events {{
     "test_run:start"    => params("test_run").desc("A test run was started on the CI server"),
     "test_run:complete" => params("test_run").desc("A test run was completed on the CI server"),
     "test_run:compared" => params("test_run").desc("The test results for a commit were compared to the results for its parent")
   }}


  # Add a link to Houston's global navigation
  #
  #    add_navigation_renderer :ci do
  #      name "Ci"
  #      icon "fa-thumbs-up"
  #      path { Houston::Ci::Engine.routes.url_helpers.ci_path }
  #      ability { |ability| ability.can? :read, Project }
  #    end


  # Add a link to feature that can be turned on for projects
  #
  #    add_project_feature :ci do
  #      name "Ci"
  #      icon "fa-thumbs-up"
  #      path { |project| Houston::Ci::Engine.routes.url_helpers.project_ci_path(project) }
  #      ability { |ability, project| ability.can? :read, project }
  #    end

end
