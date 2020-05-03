module Houston
  module Ci
    class TestRunsController < Houston::Ci::ApplicationController
      before_action :find_test_run, except: [:report_start]
      before_action :find_or_create_test_run, only: [:report_start]
      skip_before_action :verify_authenticity_token, only: [:save_results, :save_results_async, :report_start]

      def show
        @title = "Test Results for #{@test_run.sha[0...8]}"

        if request.format.oembed?
          render json: MultiJson.dump({
            version: "1.0",
            type: "link",
            provider_name: "Houston",
            author_name: @project.slug,
            title: @test_run.summary,
            html: @test_run.short_description(with_duration: true) })
        else
          render template: "houston/ci/test_runs/show"
        end
      end

      def confirm_retry
      end

      def retry
        @test_run.retry!

        build_url = if @project.ci_server.respond_to? :last_build_progress_url
          @project.ci_server.last_build_progress_url
        elsif @project.ci_server.respond_to? :last_build_url
          @project.ci_server.last_build_url
        end

        if build_url
          redirect_to build_url
        else
          redirect_to root_url, notice: "Build for #{@project.name} retried"
        end
      end

      def report_start
        head :ok
      end

      def save_results
        with_results_url do |results_url|
          @test_run.completed!(results_url)
        end

        head :ok
      end

      def save_results_async
        with_results_url do |results_url|
          Rails.logger.debug "Scheduling pulling from #{results_url} in #{ASYNC_DELAY}s"
          DelayedTestRunRecorder.set(wait: ASYNC_DELAY.seconds).perform_later(params[:commit], results_url)
        end

        head :ok
      end

    private

      def find_test_run
        @test_run = TestRun.find_by_sha!(params[:commit])
        @project = @test_run.project if @test_run
      end

      def find_or_create_test_run
        @project = Project.find_by_slug!(params[:slug])
        @test_run = @project.test_runs.find_or_create_by_sha(params[:commit]).tap do |test_run|
          raise ActiveRecord::RecordNotFound unless test_run
        end
      end

      def with_results_url
        results_url = params[:results_url]

        if results_url.blank?
          message = "#{@project.ci_server_name} is not appropriately configured to build #{@project.name}."
          additional_info = "#{@project.ci_server_name} did not supply 'results_url' when it triggered the post_build hook"
          Houston::Ci::Mailer.ci_configuration_error(@test_run, message, additional_info: additional_info).deliver!
          return
        end

        yield results_url
      end

      class DelayedTestRunRecorder < ActiveJob::Base
        self.queue_adapter = :async

        def perform(sha, results_url)
          test_run = TestRun.find_by_sha!(sha)
          Rails.logger.debug "Updating TestRun #{test_run.id} with #{results_url}"
          test_run.completed!(results_url)
        end

      end

      ASYNC_DELAY = 10

    end
  end
end
