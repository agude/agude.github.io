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
  def valid_site(dir, body: '<p>Hello.</p>', head: '', headings: '<h1>Home</h1>')
    write_fixture(dir, '_site/public/favicon.ico', 'icon-bytes')
    write_fixture(dir, '_site/images/cover.png', 'png-bytes')
    write_fixture(dir, '_site/about/index.html', <<~HTML)
      <!DOCTYPE html>
      <html lang="en"><head><title>About</title>
      <link rel="icon" href="/public/favicon.ico"></head>
      <body><h1>About</h1><p>About page.</p></body></html>
    HTML
    write_fixture(dir, '_site/index.html', <<~HTML)
      <!DOCTYPE html>
      <html lang="en"><head><title>Home</title>
      <link rel="icon" href="/public/favicon.ico">
      #{head}</head>
      <body>#{headings}#{body}</body></html>
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

  def test_valid_heading_outline_passes
    in_fixture_dir do |dir|
      valid_site(dir, headings: '<h1>Home</h1><h2>A</h2><h3>B</h3><h4>C</h4><h2>D</h2>')

      output, status = run_bin_script(SCRIPT, dir)

      assert_predicate status, :success?, output
    end
  end

  def test_missing_h1_fails
    in_fixture_dir do |dir|
      valid_site(dir, headings: '<h2>Section</h2>')

      output, status = run_bin_script(SCRIPT, dir)

      refute_predicate status, :success?
      assert_includes output, 'page has 0 <h1> headings'
    end
  end

  def test_second_h1_fails
    in_fixture_dir do |dir|
      valid_site(dir, headings: '<h1>Home</h1><h1>Saturday</h1>')

      output, status = run_bin_script(SCRIPT, dir)

      refute_predicate status, :success?
      assert_includes output, 'page has 2 <h1> headings'
    end
  end

  def test_heading_before_h1_fails
    in_fixture_dir do |dir|
      valid_site(dir, headings: '<h2>Nav</h2><h1>Home</h1>')

      output, status = run_bin_script(SCRIPT, dir)

      refute_predicate status, :success?
      assert_includes output, 'first heading is <h2> "Nav"'
    end
  end

  def test_skipped_heading_level_fails
    in_fixture_dir do |dir|
      valid_site(dir, headings: '<h1>Home</h1><h3>1. <em>Version</em> Control</h3>')

      output, status = run_bin_script(SCRIPT, dir)

      refute_predicate status, :success?
      assert_includes output, 'heading skips from <h1> "Home" to <h3> "1. Version Control"'
    end
  end

  def test_headings_in_comments_and_scripts_are_ignored
    in_fixture_dir do |dir|
      valid_site(dir, body: '<!-- <h1>Old</h1> --><script>"<h3>x</h3>"</script>')

      output, status = run_bin_script(SCRIPT, dir)

      assert_predicate status, :success?, output
    end
  end

  def test_markdown_test_page_is_exempt_from_heading_outline
    # The test page renders one of every element, several <h1>s included.
    in_fixture_dir do |dir|
      valid_site(dir)
      write_fixture(dir, '_site/test/index.html', <<~HTML)
        <!DOCTYPE html>
        <html lang="en"><head><title>Test</title>
        <link rel="icon" href="/public/favicon.ico"></head>
        <body><h1>Test</h1><h1>Heading Level 1</h1><h3>Skip</h3></body></html>
      HTML

      output, status = run_bin_script(SCRIPT, dir)

      assert_predicate status, :success?, output
    end
  end

  MATHJAX = 'https://cdnjs.cloudflare.com/ajax/libs/mathjax/3.2.2/es5/tex-mml-chtml.js'

  def test_external_script_with_sri_passes
    in_fixture_dir do |dir|
      valid_site(dir, head: %(<script src="#{MATHJAX}" integrity="sha512-abc" crossorigin="anonymous"></script>))

      output, status = run_bin_script(SCRIPT, dir)

      assert_predicate status, :success?, output
    end
  end

  def test_external_script_without_integrity_fails
    in_fixture_dir do |dir|
      valid_site(dir, head: %(<script src="#{MATHJAX}" crossorigin="anonymous"></script>))

      output, status = run_bin_script(SCRIPT, dir)

      refute_predicate status, :success?
      assert_includes output, "external <script> #{MATHJAX} has no integrity"
    end
  end

  def test_external_stylesheet_without_crossorigin_fails
    in_fixture_dir do |dir|
      valid_site(dir, head: '<link rel="stylesheet" href="//cdn.example.com/a.css" integrity="sha384-x">')

      output, status = run_bin_script(SCRIPT, dir)

      refute_predicate status, :success?
      assert_includes output, 'has no crossorigin'
    end
  end

  def test_local_and_same_origin_resources_need_no_sri
    in_fixture_dir do |dir|
      write_fixture(dir, '_site/assets/main.css', 'body {}')
      write_fixture(dir, '_site/assets/app.js', '')
      head = '<link rel="stylesheet" href="/assets/main.css"><script src="/assets/app.js"></script>' \
             '<link rel="alternate" href="https://example.com/feed.xml">' \
             '<link rel="stylesheet" href="https://alexgude.com/assets/main.css">'
      valid_site(dir, head: head)

      output, status = run_bin_script(SCRIPT, dir)

      assert_predicate status, :success?, output
    end
  end
end
