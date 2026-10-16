# frozen_string_literal: true

require 'test_helper'
require 'tmpdir'
require 'fileutils'
require 'src/infrastructure/front_matter_image_validator'

# Tests for FrontMatterImageValidator: a local front-matter `image` must
# exist on disk, whether or not the page renders it as its lead image.
class TestFrontMatterImageValidator < Minitest::Test
  Validator = Jekyll::Infrastructure::FrontMatterImageValidator

  def setup
    @source = Dir.mktmpdir('front-matter-image')
    FileUtils.mkdir_p(File.join(@source, 'books', 'covers'))
    File.write(File.join(@source, 'books', 'covers', 'dune.jpg'), 'jpg')
    @site = create_site({ 'source' => @source })
  end

  def teardown
    FileUtils.remove_entry(@source)
  end

  def doc_with(data)
    create_doc({ 'path' => '_books/dune.md' }.merge(data), '/books/dune/')
  end

  def test_existing_local_image_passes
    Validator.validate(doc_with('image' => '/books/covers/dune.jpg'), @site)
  end

  def test_missing_local_image_raises_naming_document_and_image
    doc = doc_with('image' => '/books/covers/missing.jpg')
    error = assert_raises(Jekyll::Errors::FatalException) { Validator.validate(doc, @site) }
    assert_includes error.message, '_books/dune.md'
    assert_includes error.message, '/books/covers/missing.jpg'
  end

  def test_missing_image_with_hidden_lead_image_still_raises
    doc = doc_with('image' => '/files/missing.png', 'hide_lead_image' => true)
    error = assert_raises(Jekyll::Errors::FatalException) { Validator.validate(doc, @site) }
    assert_includes error.message, '/files/missing.png'
  end

  def test_absolute_http_image_is_ignored
    Validator.validate(doc_with('image' => 'https://cdn.example.com/p.jpg'), @site)
    Validator.validate(doc_with('image' => 'http://cdn.example.com/p.jpg'), @site)
  end

  def test_hash_form_checks_path
    Validator.validate(doc_with('image' => { 'path' => '/books/covers/dune.jpg', 'alt' => 'Dune' }), @site)

    doc = doc_with('image' => { 'path' => '/books/covers/missing.jpg', 'alt' => 'Missing' })
    error = assert_raises(Jekyll::Errors::FatalException) { Validator.validate(doc, @site) }
    assert_includes error.message, '/books/covers/missing.jpg'
  end

  def test_no_image_passes
    Validator.validate(doc_with({}), @site)
  end

  def test_directory_is_not_an_image
    doc = doc_with('image' => '/books/covers')
    assert_raises(Jekyll::Errors::FatalException) { Validator.validate(doc, @site) }
  end
end

# Tests for the :pre_render hook registration.
class TestFrontMatterImageValidatorHook < Minitest::Test
  def test_hook_raises_for_page_with_missing_image
    Dir.mktmpdir('front-matter-image-hook') do |source|
      site = create_site({ 'source' => source })
      page = create_doc({ 'path' => 'about.md', 'image' => '/files/missing.png' }, '/about/')
      page.site = site
      assert_raises(Jekyll::Errors::FatalException) { validator_hooks(:pages).each { |h| h.call(page, {}) } }
    end
  end

  def test_hook_is_registered_for_documents
    refute_empty validator_hooks(:documents)
  end

  private

  # Other plugins register :pre_render hooks too; call only this file's.
  def validator_hooks(owner)
    hooks = Jekyll::Hooks.instance_variable_get(:@registry).dig(owner, :pre_render) || []
    hooks.select { |h| h.source_location.first.end_with?('front_matter_image_validator.rb') }
  end
end
