Houston::Ci::Engine.routes.draw do

  get "test_runs/:commit", to: "test_runs#show"
  get "projects/:slug/test_runs/:commit", to: "test_runs#show", :as => :test_run
  post "projects/:slug/test_runs/:commit", to: "test_runs#report_start"
  get "projects/:slug/test_runs/:commit/retry", to: "test_runs#confirm_retry", :as => :retry_test_run
  post "projects/:slug/test_runs/:commit/retry", to: "test_runs#retry"
  put "projects/:slug/test_runs/:commit/results", to: "test_runs#save_results"

  get "projects/:slug/tests", to: "project_tests#index", as: :project_tests
  get "projects/:slug/tests/:id", to: "project_tests#show", as: :project_test

end
