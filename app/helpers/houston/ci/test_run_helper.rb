module Houston
  module Ci
    module TestRunHelper

      def test_status(test)
        case test[:status].to_s
        when "pass"; "pass"
        when "skip"; "skip"
        when "fail", "regression"; "fail"
        else
          raise NotImplementedError.new "TestRunHelper#test_status doesn't know about the status #{test[:status].inspect}"
        end
      end

      def test_run_summary(test_run)
        subject = {
          "pass" => "#{test_run.total_count} tests passed!",
          "fail" => test_run_fail_summary(test_run),
          "error" => "tests are broken",
          "aborted" => "aborted"
        }.fetch(
          test_run.result.to_s,
          (test_run.created_at ? "started #{distance_of_time_in_words(test_run.created_at, Time.now)} ago" : ""))

        subject << " [#{test_run.branch}]" if test_run.branch

        subject
      end

      def test_run_fail_summary(test_run)
        if test_run.real_fail_count.zero?
          "the build exited unsuccessfully after running #{test_run.total_count} #{test_run.total_count == 1 ? "test" : "tests"}"
        else
          "#{test_run.real_fail_count} #{test_run.real_fail_count == 1 ? "test" : "tests"} failed"
        end
      end

      def commit_test_status(test_run, test_result)
        status = test_result.status if test_result
        status = "untested" if test_run.nil?
        status = "pending" if test_run && test_run.pending?
        status = "aborted" if test_run && test_run.aborted?
        status ||= "unknown"

        css = "project-test-status project-test-status-#{status}"

        if test_run
          link_to status, test_run_url(slug: test_run.project.slug, commit: test_run.sha), class: css
        else
          "<span class=\"#{css}\">#{status}</span>".html_safe
        end
      end

      def test_results_pass_count(test)
        test[:results].count { |result| result == "pass" }
      end

      def test_results_fail_count(test)
        test[:results].count { |result| result == "fail" }
      end

      def test_results_count(test)
        test[:results].count { |result| !result.nil? }
      end

      def test_results_graph(test)
        html = "<svg class=\"dot-graph\">"
        percent = 100 / test[:results].length.to_f
        left = 0
        test[:results].reverse_each do |result|
          html << "<rect x=\"#{left}%\" y=\"0\" rx=\"2\" ry=\"2\" width=\"#{percent}%\" height=\"100%\" class=\"dot-graph-rect #{result}\" data-index=\"0\"></rect>" if result
          left += percent
        end
        html << "</svg>"
        html.html_safe
      end

      def area_graph(options={})
        StaticChart::Area.new(options)
      end

      def commit_test_message(commit)
        message = commit.message[/^.*$/]
        return message unless @project
        return message unless @project.repo.respond_to? :commit_url
        link_to message, @project.repo.commit_url(commit), target: "_blank"
      end

    end
  end
end
