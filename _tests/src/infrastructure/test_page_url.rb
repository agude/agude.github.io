# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../../_plugins/src/infrastructure/page_url'

# Tests URL lookup across document and Liquid payload shapes.
class TestPageUrl < Minitest::Test
  def test_reads_document_accessor_when_hash_lookup_has_no_url
    document = Struct.new(:url, :data) do
      def [](_key)
        nil
      end
    end.new('/books/example.html', {})

    assert_equal '/books/example.html', Jekyll::Infrastructure::PageUrl.fetch(document)
  end

  def test_reads_liquid_page_hash
    assert_equal '/books/example.html', Jekyll::Infrastructure::PageUrl.fetch({ 'url' => '/books/example.html' })
  end

  def test_falls_back_to_hash_when_accessor_is_nil
    page = Struct.new(:url, :data) do
      def [](key)
        data[key]
      end
    end.new(nil, { 'url' => '/books/example.html' })

    assert_equal '/books/example.html', Jekyll::Infrastructure::PageUrl.fetch(page)
  end

  def test_missing_page_has_no_url
    assert_nil Jekyll::Infrastructure::PageUrl.fetch(nil)
  end
end
