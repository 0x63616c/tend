# Exercise the real lane with recorded actions: no Apple access or signing changes.
ENV["ASC_BETA_FEEDBACK_EMAIL"] = "ci@example.invalid"
ENV["ASC_KEY_ID"] = "test-key"
ENV["ASC_ISSUER_ID"] = "test-issuer"
ENV["ASC_KEY_CONTENT"] = "test-only"
ENV.delete("ASC_KEY_PATH")

module UI
  def self.user_error!(message)
    raise message
  end
end

class ReleaseCheck
  attr_reader :calls
  attr_accessor :fail_tests

  def initialize
    @calls = []
    instance_eval(File.read(File.expand_path("../fastlane/Fastfile", __dir__)))
  end

  def default_platform(*); end
  def desc(*); end
  def platform(*)
    yield
  end
  def lane(name, &block)
    define_singleton_method(name, &block)
  end
  alias private_lane lane

  def sh(*args)
    @calls << [:sh, args]
    raise "test failure" if fail_tests
  end

  def app_store_connect_api_key(**args)
    args
  end

  def latest_testflight_build_number(**args)
    @calls << [:latest, args]
    17
  end

  def build_app(**args)
    @calls << [:build, args]
  end

  def upload_to_testflight(**args)
    @calls << [:upload, args]
  end
end

check = ReleaseCheck.new
ENV.delete("TENDR_PROFILE_UUID")
ENV.delete("GITHUB_ACTIONS")
check.beta({})
raise "release order" unless check.calls.map(&:first) == [:sh, :latest, :build, :upload]
build = check.calls.assoc(:build).last
raise "local signing changed" unless build[:export_xcargs] == "-allowProvisioningUpdates" && build[:export_options].empty?
raise "next build number" unless build[:xcargs].include?("CURRENT_PROJECT_VERSION=18")
upload = check.calls.assoc(:upload).last
raise "distribution" unless upload[:groups] == ["Owner Preview"] && upload[:skip_waiting_for_build_processing] == false && upload[:build_number] == "18"

check.calls.clear
ENV["GITHUB_ACTIONS"] = "true"
begin
  check.beta({})
  raise "accepted missing signing"
rescue RuntimeError => error
  raise unless error.message.include?("CI signing is missing")
end
raise "uploaded without signing" if check.calls.assoc(:upload)

check.calls.clear
ENV["TENDR_PROFILE_UUID"] = "12345678-1234-1234-1234-123456789ABC"
check.beta({})
build = check.calls.assoc(:build).last
raise "CI archive signing" unless build[:xcargs].include?("CODE_SIGN_STYLE=Manual") && build[:xcargs].include?("PROVISIONING_PROFILE_SPECIFIER=#{ENV['TENDR_PROFILE_UUID']}")
raise "CI export signing" unless build[:export_options][:provisioningProfiles] == { "com.calumwebb.still" => ENV["TENDR_PROFILE_UUID"] } && build[:export_xcargs].empty?

check.calls.clear
check.fail_tests = true
begin
  check.beta({})
  raise "ignored failing tests"
rescue RuntimeError => error
  raise unless error.message == "test failure"
end
raise "released after failing tests" unless check.calls.map(&:first) == [:sh]
puts "Release checks passed (local signing, CI signing, next build, distribution, failure gates)."
