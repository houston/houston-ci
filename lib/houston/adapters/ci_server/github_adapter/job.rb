require "juniter"
require "zip"

module Houston
  module Adapters
    module CIServer
      class GithubAdapter
        class Job

          class WorkflowNotFound < RuntimeError; end
          class WorkflowRunNotFound < RuntimeError; end

          def initialize(project, workflow_file_name)
            @project = project
            @workflow_file_name = workflow_file_name
            @coverage_reports = []
          end

          attr_reader :project

          def job_url
            workflow[:html_url]
          end

          def build!(commit)
            # No way to trigger a GitHub Action Workflow run via an API
            raise NotImplementedError
          end

          def retry!(commit)
            Houston.try({ max_tries: 5 }, Faraday::Error::ConnectionFailed) do
              Houston.github.post("/repos/#{repo_path}/actions/runs/#{latest_run_for(commit)[:id]}/rerun")
            end
          end

          def fetch_results!(results_url)
            run_id = /\/runs\/(.*)$/i.match(results_url)[1]
            { total_count: 0,
              regression_count: 0, # GH doesn't provide this
              fail_count: 0,
              pass_count: 0,
              skip_count: 0,
              tests: [] }.tap do |results|
              artifacts_for(run_id).each do |artifact|
                parse_coverage(artifact[:data]) if artifact[:name] =~ COVERAGE_REGEX
                next unless artifact[:name] =~ XML_FILE_REGEX

                Juniter.parse(artifact[:data]).tap do |test_file|
                  test_file.test_suites.test_suites.each do |suite|
                    results[:total_count] += suite.test_count.to_i
                    results[:fail_count] += suite.failure_count.to_i + suite.error_count.to_i
                    results[:skip_count] += suite.skipped_count.to_i
                    results[:pass_count] += suite.test_count.to_i - (suite.failure_count.to_i + suite.error_count.to_i + suite.skipped_count.to_i)
                    results[:tests].concat translate_test_suite(suite)
                  end
                end
              end

              results[:coverage] = coverage_reports.flat_map { |report| report[:coverage] || [] }
              results.merge! compile_coverage_metrics!
              results[:duration] = fetch_duration_of! run_id
              results[:result] = results[:tests].pluck(:status).none? { |status| %i{fail error}.include?(status) } ? :pass : :fail
            end
          end

        private
          attr_reader :workflow_file_name, :coverage_reports

          def latest_run_for(commit)
            Houston.github.get("/repos/#{repo_path}/actions/workflows/#{workflow[:id]}/runs")[:workflow_runs]
              .select { |run| run[:head_sha] == commit }
              .sort_by { |run| run[:created_at] }
              .reverse!
              .first
              .tap { |run| raise WorkflowRunNotFound if run.nil? }
          end

          def fetch_duration_of!(run_id)
            jobs = jobs_for(run_id)
            started_at = jobs.pluck(:started_at).compact.min
            completed_at = jobs.pluck(:completed_at).compact.max
            translate_duration(completed_at - started_at)
          end

          def artifacts_for(run_id)
            Enumerator.new do |e|
              github_artifacts_for(run_id).each do |artifact|
                with_downloaded(artifact) do |zipped_io|
                  Zip::File.open_buffer(zipped_io) do |zip|
                    zip.each do |entry|
                      e.yield({ name: entry.name, data: entry.get_input_stream.read })
                    end
                  end
                end
              end
            end
          end

          def github_artifacts_for(run_id)
            Houston.github.get("/repos/#{repo_path}/actions/runs/#{run_id}/artifacts")[:artifacts]
          end

          def with_downloaded(archive)
            yield StringIO.new(Houston.github.get(archive[:archive_download_url]))
          end

          def jobs_for(run_id)
            Houston.github.get("/repos/#{repo_path}/actions/runs/#{run_id}/jobs")[:jobs]
          end

          def workflow
            @workflow_id ||= Houston.github.get("/repos/#{repo_path}/actions/workflows")[:workflows]
              .find { |workflow| workflow[:path] =~ /#{Regexp.escape(workflow_file_name)}$/i }
              .tap { |workflow| raise WorkflowNotFound if workflow.nil? }
          end

          def repo_path
            @repo_path ||= Addressable::URI.parse(project.repo.project_url).path[1..-1]
          end

          def translate_test_suite(test_suite)
            test_suite.test_cases.map do |test_case|
              { name: translate_test_name(test_case.name),
                suite: test_suite.name,
                age: 0, # Not something GH reports.
                status: test_case.result.status }.tap do |json|
                json[:duration] = translate_duration(test_case.duration) unless test_case.duration.nil?
                if test_case.result.error?
                  json[:error_message] = test_case.result.message
                  json[:error_backtrace] = test_case.result.description
                end
              end
            end
          end

          def translate_test_name(name)
            name.gsub(/^test_/, "").gsub("_", " ")
          end

          def translate_test_status(status)
            return :fail if status == :error
            status
          end

          def translate_duration(seconds)
            seconds * 1000
          end

          def parse_coverage(serialized)
            json = MultiJson.parse(serialized)
            coverage_reports << {
              metrics: json["metrics"] || {},
              files: translate_file_coverage(json["files"])
            }
          end

          def compile_coverage_metrics!
            # TODO: Averaging isn't the right solution, since some slices may include more
            # files or lines than others. Coverage.json supplies total lines and covered lines,
            # so calculating our own master percentage shouldn't be an issue, but I'm not sure
            # how strength is calculated, so I'm not sure how to derive that over the span of
            # several files...
            all_metrics = coverage_reports.map { |report| report[:metrics] }
            percentages = all_metrics.map { |metrics| metrics["covered_percent"] }.compact
            strengths = all_metrics.map { |metrics| metrics["covered_strength"] }.compact
            covered_percent = percentages.empty? ? 0 : percentages.sum / (100.0 * percentages.count)
            covered_strength = strengths.empty? ? 0 : strengths.sum / (100.0 * strengths.count)

            { covered_percent: covered_percent, covered_strength: covered_strength }
          end

          def translate_file_coverage(files)
            Array.wrap(files).map do |file|
              { filename: get_relative_filename(file["filename"]),
                coverage: file["coverage"] }
            end
          end

          def get_relative_filename(filename)
            return filename unless (relative_filename = filename[WORKSPACE_MATCHER])

            relative_filename.split("/")[2..-1].join("/")
          end

          COVERAGE_REGEX = /coverage\.json$/i.freeze
          XML_FILE_REGEX = /\.xml$/i.freeze
          WORKSPACE_MATCHER = /(?<=\/runner\/work\/).*/.freeze

        end
      end
    end
  end
end
