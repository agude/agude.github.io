# frozen_string_literal: true

require_relative '../../../../support/related_book_finder_test_case'
require 'tmpdir'
require 'open3'
require 'rbconfig'

# Exercises selection reuse through the HTML tag and the Markdown footer.
class TestRelatedBooksFinderCache < RelatedBookFinderTestCase
  def render_both_modes(site, page)
    context = create_context({}, { site: site, page: page })
    html = Liquid::Template.parse('{% related_books %}').render!(context)
    markdown = Jekyll::MarkdownOutput::MarkdownOutputAssembler.build_related_books_section(site, page)
    [html, markdown]
  end

  def test_html_and_markdown_keep_the_same_ordered_related_list
    books, site = @helper.setup_series_books(4)
    html, markdown = render_both_modes(site, books.first)
    html_titles = Nokogiri::HTML5.fragment(html).css('.card-text > a').map { |a| a.text.strip }
    markdown_titles = markdown.scan(/^- \[_([^\]]+)_\]/).flatten

    assert_equal books.drop(1).map { |book| book.data['title'] }, html_titles
    assert_equal html_titles, markdown_titles
  end

  def test_filters_candidates_once_across_output_modes
    books, site = @helper.setup_series_books(4)
    calls = 0
    trace = TracePoint.new(:call) do |event|
      calls += 1 if event.defined_class == Jekyll::Books::Related::Finder && event.method_id == :fetch_potential_books
    end

    trace.enable { render_both_modes(site, books.first) }

    assert_equal 1, calls
  end

  def test_limits_pages_and_sites_do_not_share_results
    books, site = @helper.setup_series_books(4)
    finder = Jekyll::Books::Related::Finder

    assert_equal [books[1].url], finder.new(site, books[0], 1).find[:books].map(&:url)
    assert_equal books.drop(1).map(&:url), finder.new(site, books[0], 3).find[:books].map(&:url)
    assert_equal [books[0].url], finder.new(site, books[1], 1).find[:books].map(&:url)

    other_books, other_site = @helper.setup_series_books(4)
    other_books[1].data['published'] = false
    assert_equal [other_books[2].url], finder.new(other_site, other_books[0], 1).find[:books].map(&:url)
  end

  def test_post_read_discards_previous_selection
    books, site = @helper.setup_series_books(4)
    finder = Jekyll::Books::Related::Finder
    assert_equal [books[1].url], finder.new(site, books[0], 1).find[:books].map(&:url)

    books[1].data['published'] = false
    Jekyll::Hooks.trigger(:site, :post_read, site)

    assert_equal [books[2].url], finder.new(site, books[0], 1).find[:books].map(&:url)
  end

  def test_same_site_process_rebuilds_after_book_data_changes
    Dir.mktmpdir('related-rebuild') do |source|
      write_rebuild_fixture(source)
      script = <<~RUBY
        require 'jekyll'
        site = Jekyll::Site.new(Jekyll.configuration('source' => ARGV[0], 'quiet' => true))
        site.process
        before = site.collections['books'].docs.find { |book| book.data['title'] == 'Current' }
        abort 'first selection wrong' unless Jekyll::Books::Related::Finder.new(site, before, 1).find[:books].first.data['title'] == 'Second'
        path = File.join(ARGV[0], '_books/second.md')
        File.write(path, File.read(path).sub('book_number: 2', 'book_number: 4'))
        site.process
        after = site.collections['books'].docs.find { |book| book.data['title'] == 'Current' }
        abort 'stale selection after rebuild' unless Jekyll::Books::Related::Finder.new(site, after, 1).find[:books].first.data['title'] == 'Third'
      RUBY
      output, status = Open3.capture2e(RbConfig.ruby, '-e', script, source)
      assert status.success?, output
    end
  end

  def write_rebuild_fixture(source)
    root = File.expand_path('../../../../..', __dir__)
    File.symlink(File.join(root, '_plugins'), File.join(source, '_plugins'))
    config = {
      'url' => 'https://example.com',
      'author' => { 'name' => 'Owner', 'url' => '/resume/' },
      'collections' => { 'books' => { 'output' => true } },
      'standard_site' => { 'publication_uri' => 'at://did:plc:fixture/site.standard.publication/fixture' },
      'plugin_log_level' => 'error',
    }
    File.write(File.join(source, '_config.yml'), config.to_yaml)
    FileUtils.mkdir_p(File.join(source, '_books'))
    %w[Current Second Third].each_with_index do |title, index|
      File.write(File.join(source, "_books/#{title.downcase}.md"), <<~MARKDOWN)
        ---
        title: #{title}
        book_authors: Fixture Author
        book_number: #{index + 1}
        series: Fixture Saga
        wikidata_qid: Q#{index + 1}
        date: 2024-01-01
        ---
        Fixture prose.
      MARKDOWN
    end
  end
end
