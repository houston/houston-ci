# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

# Load Houston
require "dummy/houston"
Rails.application.initialize! unless Rails.application.initialized?

require "rails/test_help"
require "support/houston/adapters/version_control/mock_adapter"
require "support/houston/adapters/ci_server/mock_adapter"
require "houston/test_helpers"
require "houston/commits/test_helpers"

if ENV["CI"] == "true"
  require "minitest/reporters"
  MiniTest::Reporters.use! [MiniTest::Reporters::DefaultReporter.new,
                            MiniTest::Reporters::JUnitReporter.new]
else
  require "minitest/reporters/turn_reporter"
  MiniTest::Reporters.use! Minitest::Reporters::TurnReporter.new
end

# Filter out Minitest backtrace while allowing backtrace
# from other libraries to be shown.
Minitest.backtrace_filter = Minitest::BacktraceFilter.new

FactoryGirl.factories.clear
FactoryGirl.definition_file_paths = [File.expand_path("../factories", __FILE__)]
FactoryGirl.find_definitions


Houston.observer.async = false
Houston.triggers.async = false


class ActiveSupport::TestCase
  include FactoryGirl::Syntax::Methods
  include Houston::TestHelpers
  include Houston::Commits::TestHelpers

  # Load fixtures from the engine
  self.fixture_path = File.expand_path("../fixtures", __FILE__)

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  def assert_deep_equal(expected_value, actual_value)
    differences = differences_between_values(expected_value, actual_value)
    assert differences.none?, differences.join("\n")
  end

  def differences_between_values(expected_value, actual_value, context=[])
    if expected_value.is_a?(Float) && actual_value.is_a?(Float)
      differences_between_floats(expected_value, actual_value, context)
    elsif expected_value.is_a?(Array) && actual_value.is_a?(Array)
      differences_between_arrays(expected_value, actual_value, context)
    elsif expected_value.is_a?(Hash) && actual_value.is_a?(Hash)
      differences_between_hashes(expected_value, actual_value, context)
    else
      if expected_value == actual_value
        []
      else
        ["Expected value#{format_context(context)} to be #{expected_value.inspect} but was #{actual_value.inspect}"]
      end
    end
  end

  def differences_between_floats(expected_float, actual_float, context=[])
    if (expected_float - actual_float).abs < 0.001
      []
    else
      ["Expected value#{format_context(context)} to be #{expected_float.inspect} but was #{actual_float.inspect}"]
    end
  end

  def differences_between_arrays(expected_array, actual_array, context=[])
    if expected_array.length != actual_array.length
      return ["Expected value#{format_context(context)} to be an array with #{expected_array.length} values, but has #{actual_array.length} values"]
    end

    differences = []
    expected_array.each_with_index do |expected_value, i|
      actual_value = actual_array[i]
      differences.concat differences_between_values(expected_value, actual_value, context.dup.push(i))
    end

    differences
  end

  def differences_between_hashes(expected_hash, actual_hash, context=[])
    differences = []

    missing_keys = expected_hash.keys - actual_hash.keys
    if missing_keys.any?
      differences << "Expected value#{format_context(context)} to have keys #{missing_keys.inspect}, but is missing them"
    end

    extra_keys = actual_hash.keys - expected_hash.keys
    if extra_keys.any?
      differences << "Expected value#{format_context(context)} has keys #{extra_keys.inspect}, but is not expected to have them"
    end

    shared_keys = expected_hash.keys & actual_hash.keys
    shared_keys.each do |key|
      expected_value = expected_hash[key]
      actual_value = actual_hash[key]
      differences.concat differences_between_values(expected_value, actual_value, context.dup.push(key))
    end

    differences
  end

  def format_context(context)
    return "" if context.none?
    path = context.shift.to_s
    context.each do |segment|
      path << "[#{segment.inspect}]"
    end
    " of #{path}"
  end

end

require "capybara/rails"

class ActionDispatch::IntegrationTest
  include Capybara::DSL

  # Load fixtures from the engine
  self.fixture_path = File.expand_path("../fixtures", __FILE__)

end

class ActionController::TestCase
  include Devise::Test::ControllerHelpers
end
