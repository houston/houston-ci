# Load Houston
require "houston/application"

# Configure Houston
Houston.config do

  # Houston should load config/database.yml from this module
  # rather than from Houston Core.
  root Pathname.new File.expand_path("../../..",  __FILE__)

  # Give dummy values to these required fields.
  host "houston.test.com"
  secret_key_base "e6d990489436fd3af7ebba35657d8b"
  mailer_sender "houston@test.com"

  # Mount this module on the dummy Houston application.
  use :ci do
    ci_server :jenkins do
      host "jenkins.example.com"
    end
  end

end
