# Github::CommitStatusReport
#
# Publishes commit status to GitHub.
# Status is [pending, success, error, failure]
#
# See also:
#   * http://developer.github.com/v3/repos/statuses/#create-a-status
#   * https://gist.github.com/justincampbell/5066394
#
# You can read status back via an API as well:
#   https://api.github.com/repos/:owner/:repo/statuses/:sha?access_token=:token
#
module Github
  class CommitStatusReport

    def self.publish!(test_run)
      self.new(test_run).publish!
    end

    def initialize(test_run)
      @access_token = Houston::Commits.config.github[:access_token]
      @project = test_run.project
      @test_run = test_run
    end

    attr_reader :access_token, :project, :test_run



    def publish!
      return no_access_token unless access_token

      Houston.try({max_tries: 5},
          Faraday::ConnectionFailed,
          Faraday::Error::ConnectionFailed
      ) do
        Rails.logger.info "[github/commit_status_report:publish!] POST #{state} to #{github_status_url}"
        response = Faraday.post(github_status_url, payload)
        bad_response(response) unless response.success?
        response
      end
    end

    def github_status_url
      project.repo.commit_status_url(test_run.sha) << "?access_token=#{access_token}"
    end

    def state
      return "pending" unless test_run.completed?
      {"pass" => "success", "fail" => "failure"}.fetch(test_run.result.to_s, "error")
    end

    def payload
      MultiJson.dump(
        state: state,
        context: "jenkins",
        description: test_run.short_description,
        target_url: test_run.url)
    end



    def no_access_token
      message = "Houston can publish your test results to GitHub"
      additional_info = "Supply github/access_token in Houston's config.rb"
      Houston::Ci::Mailer.ci_configuration_error(test_run, message, additional_info: additional_info).deliver!
    end

    def bad_response(response)
      message = "Houston was unable to publish your commit status to GitHub"
      additional_info = "GitHub returned #{response.status}: #{response.body} (URL: #{github_status_url})"
      Houston::Ci::Mailer.ci_configuration_error(test_run, message, additional_info: additional_info).deliver!
    end

  end
end
