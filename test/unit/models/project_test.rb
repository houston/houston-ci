require "test_helper"

class ProjectTest < ActiveSupport::TestCase
  attr_reader :project

  context "Adapters:" do
    should "find the specified built-in CIServer adapter" do
      project = Project.new(ci_server_name: "None")
      assert_equal Houston::Adapters::CIServer::NoneAdapter, project.ci_server_adapter
    end

    should "find the specified extension CIServer adapter" do
      project = Project.new(ci_server_name: "Mock")
      assert_equal Houston::Adapters::CIServer::MockAdapter, project.ci_server_adapter
    end
  end

end
