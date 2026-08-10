# frozen_string_literal: true

require_relative '../test_helper'
require_relative 'bin_script_helper'

# Covers _bin/check_links.rb. The script is HTMLProofer configuration, so
# the behaviour worth pinning is the configuration itself: which classes of
# problem fail the build, and which URLs are deliberately not fetched.
# An HTMLProofer upgrade that renames or drops one of these options would
# otherwise silently stop checking the site.
class TestCheckLinks < Minitest::Test
  include BinScriptHelper

  SCRIPT = 'check_links.rb'

  # A minimal site that HTMLProofer accepts, including the favicon and
  # OpenGraph tags the `checks` list demands.
  def valid_site(dir, body: '<p>Hello.</p>', head: '')
    write_fixture(dir, '_site/public/favicon.ico', 'icon-bytes')
    write_fixture(dir, '_site/images/cover.png', 'png-bytes')
    write_fixture(dir, '_site/about/index.html', <<~HTML)
      <!DOCTYPE html>
      <html lang="en"><head><title>About</title>
      <link rel="icon" href="/public/favicon.ico"></head>
      <body><p>About page.</p></body></html>
    HTML
    write_fixture(dir, '_site/index.html', <<~HTML)
      <!DOCTYPE html>
      <html lang="en"><head><title>Home</title>
      <link rel="icon" href="/public/favicon.ico">
      #{head}</head>
      <body>#{body}</body></html>
    HTML
  end

  def test_clean_site_passes
    in_fixture_dir do |dir|
      valid_site(dir, body: '<p><a href="/about/">About</a></p>')

      output, status = run_bin_script(SCRIPT, dir)

      assert_predicate status, :success?, output
    end
  end

  def test_broken_internal_link_fails
    in_fixture_dir do |dir|
      valid_site(dir, body: '<p><a href="/nope/">Missing</a></p>')

      output, status = run_bin_script(SCRIPT, dir)

      refute_predicate status, :success?
      assert_includes output, 'HTML-Proofer found 1 failure'
      assert_includes output, '/nope/'
    end
  end

  def test_missing_image_fails
    in_fixture_dir do |dir|
      valid_site(dir, body: '<img src="/images/gone.png" alt="Gone">')

      _output, status = run_bin_script(SCRIPT, dir)

      refute_predicate status, :success?
    end
  end

  def test_empty_alt_text_fails
    # ignore_empty_alt: false — decorative-looking images must still carry
    # real alt text on this site.
    in_fixture_dir do |dir|
      valid_site(dir, body: '<img src="/images/cover.png" alt="">')

      _output, status = run_bin_script(SCRIPT, dir)

      refute_predicate status, :success?
    end
  end

  def test_external_links_are_not_fetched
    # CI has no reliable network budget for external hosts; a domain that
    # cannot resolve must not fail the build.
    in_fixture_dir do |dir|
      valid_site(dir, body: '<p><a href="https://this-host-does-not-exist.invalid/x">External</a></p>')

      output, status = run_bin_script(SCRIPT, dir)

      assert_predicate status, :success?, output
    end
  end

  def test_at_protocol_uris_are_not_fetched
    # standard.site verification link tags are at:// URIs, not fetchable.
    in_fixture_dir do |dir|
      valid_site(dir, head: '<link rel="alternate" href="at://did:plc:example/site.standard.document/abc">')

      output, status = run_bin_script(SCRIPT, dir)

      assert_predicate status, :success?, output
    end
  end

  def test_livereload_script_is_not_fetched
    # `make serve` injects /livereload.js, which does not exist on disk.
    in_fixture_dir do |dir|
      valid_site(dir, body: '<script src="/livereload.js?snipver=1"></script>')

      output, status = run_bin_script(SCRIPT, dir)

      assert_predicate status, :success?, output
    end
  end
end
