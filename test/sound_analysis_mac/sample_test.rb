# frozen_string_literal: true

require "test_helper"

class SoundAnalysisMacSampleTest < Test::Unit::TestCase
  test "perform echoes input from skeleton implementation" do
    assert_equal("hello", SoundAnalysisMac.perform("hello"))
    # TODO: Replace with a meaningful assertion once you implement perform.
  end
end
