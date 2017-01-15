module Houston
  module Ci
    class Mailer < ViewMailer
      helper TestRunHelper
      include TestRunHelper
      include ActionView::Helpers::DateHelper

      self.stylesheets = stylesheets + %w{
        houston/ci/test_run.scss
      }


      def test_results(test_run, recipients, options={})
        @test_run = test_run
        @project = test_run.project

        mail({
          to:       recipients,
          subject:  "#{@project.name}: #{test_run_summary(test_run)}",
          template: "houston/ci/test_runs/show"
        })
      end


      def ci_configuration_error(test_run, message, options={})
        @test_run = test_run
        @project = test_run.project
        @message = message
        @additional_info = options[:additional_info]

        mail({
          to:       options.fetch(:to, @project.team_owners),
          subject:  "#{@project.name}: configuration error",
          template: "houston/ci/mailer/ci_configuration_error"
        })
      end


    end
  end
end
