module Houston::Ci
  class ApplicationController < ::ApplicationController
    layout "houston/ci/application"
    helper "houston/ci/test_run"
  end
end
