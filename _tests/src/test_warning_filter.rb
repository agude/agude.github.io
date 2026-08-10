# frozen_string_literal: true

require_relative '../test_helper'

# Guards the GemWarningFilter installed in test_helper.rb. Silencing warnings
# is only safe while the filter stays narrow: if it ever starts swallowing
# warnings raised by _plugins/ or _tests/, a real deprecation would vanish
# from CI output with nothing to notice it.
class TestWarningFilter < Minitest::Test
  def captured_warning(message)
    buffer = StringIO.new
    original = $stderr
    $stderr = buffer
    Warning.warn(message)
    buffer.string
  ensure
    $stderr = original
  end

  def gem_path(relative)
    "#{File.join(Gem.path.first, 'gems')}/#{relative}"
  end

  def test_warnings_from_installed_gems_are_dropped
    message = "#{gem_path('liquid-4.0.4/lib/liquid/errors.rb')}:9: " \
              "warning: literal string will be frozen in the future\n"

    assert_empty captured_warning(message)
  end

  def test_warnings_from_plugin_code_still_surface
    message = "#{File.expand_path('../../_plugins/src/example.rb', __dir__)}:1: warning: real problem\n"

    assert_includes captured_warning(message), 'real problem'
  end

  def test_warnings_from_test_code_still_surface
    message = "#{File.expand_path('../example_test.rb', __dir__)}:1: warning: real problem\n"

    assert_includes captured_warning(message), 'real problem'
  end

  def test_warnings_with_no_source_path_still_surface
    assert_includes captured_warning("warning: something happened\n"), 'something happened'
  end

  def test_a_gem_named_path_outside_the_gem_dir_still_surfaces
    # The filter anchors on the real gem directory, so a repo file that
    # merely mentions a gem name is not mistaken for gem noise.
    message = "/workspace/_tests/gems/liquid-4.0.4/thing.rb:1: warning: real problem\n"

    assert_includes captured_warning(message), 'real problem'
  end
end
