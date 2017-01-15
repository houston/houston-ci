require "test_helper"

class TestRunsControllerTest < ActionController::TestCase
  tests Houston::Ci::TestRunsController

  setup do
    @routes = Houston::Ci::Engine.routes
    @project = create(:project, ci_server_name: "Mock")
    @test_run = @project.test_runs.create!(sha: "whatever")
    @environment = "production"
  end

  test "GET #retry should retry the test run" do
    mock.instance_of(TestRun).retry!
    get :retry, params: { slug: @project.slug, commit: @test_run.sha }
    assert_redirected_to "/test"
  end

end
