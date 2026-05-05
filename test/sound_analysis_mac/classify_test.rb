# frozen_string_literal: true

require "test_helper"

class SoundAnalysisMacTest < Test::Unit::TestCase
  FIXTURE = File.expand_path("../fixtures/sample.aiff", __dir__)

  test "classify returns non-empty newline-separated label-confidence pairs for speech audio" do
    output = SoundAnalysisMac.classify(FIXTURE)
    assert_kind_of(String, output)
    assert_false(output.strip.empty?, "Expected non-empty classification, got: #{output.inspect}")

    pairs = output.split("\n").map { |line| line.split("\t") }
    assert(pairs.all? { |p| p.length == 2 }, "Expected 'label\\tconfidence' pairs, got: #{output.inspect}")

    pairs.each do |label, confidence|
      assert_false(label.empty?, "Expected non-empty label")
      f = Float(confidence)
      assert(f >= 0.0 && f <= 1.0, "Expected 0..1 confidence, got: #{confidence.inspect}")
    end

    labels = pairs.map(&:first)
    assert(labels.include?("speech"), "Expected 'speech' label for say-generated audio, got labels: #{labels.uniq.inspect}")
  end

  test "classify raises Errno::ENOENT for nonexistent path" do
    assert_raise(Errno::ENOENT) do
      SoundAnalysisMac.classify("/nonexistent/path/missing.aiff")
    end
  end

  test "classify raises Errno::ENOENT for empty path argument" do
    assert_raise(Errno::ENOENT) do
      SoundAnalysisMac.classify("")
    end
  end
end
