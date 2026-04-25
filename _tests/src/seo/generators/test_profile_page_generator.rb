# frozen_string_literal: true

require_relative '../../../test_helper'

# Tests for Jekyll::SEO::Generators::ProfilePageLdGenerator module.
#
# Verifies that the generator correctly creates JSON-LD structured data for
# profile/linktree pages.
class TestProfilePageLdGenerator < Minitest::Test
  def setup
    @site_config = {
      'url' => 'https://alexgude.com',
      'baseurl' => '',
      'title' => 'Alex Gude',
      'author' => {
        'name' => 'Alexander Gude',
        'linkedin' => 'alexandergude',
        'github' => 'agude',
        'bluesky' => 'alexgude.com',
      },
    }
  end

  def test_generate_hash_linktree
    doc = create_linktree_doc
    site = create_site(@site_config)
    result = Jekyll::SEO::Generators::ProfilePageLdGenerator.generate_hash(doc, site)

    assert_equal 'https://schema.org', result['@context']
    assert_equal 'ProfilePage', result['@type']
    assert_equal 'https://alexgude.com/linktree/', result['url']
  end

  def test_generate_hash_includes_main_entity
    doc = create_linktree_doc
    site = create_site(@site_config)
    result = Jekyll::SEO::Generators::ProfilePageLdGenerator.generate_hash(doc, site)

    assert result.key?('mainEntity'), 'Should include mainEntity'
    assert_equal 'Person', result['mainEntity']['@type']
    assert_equal 'Alexander Gude', result['mainEntity']['name']
  end

  def test_generate_hash_main_entity_includes_same_as
    doc = create_linktree_doc
    site = create_site(@site_config)
    result = Jekyll::SEO::Generators::ProfilePageLdGenerator.generate_hash(doc, site)

    same_as = result['mainEntity']['sameAs']
    assert same_as.is_a?(Array), 'sameAs should be an array'
    assert_includes same_as, 'https://www.linkedin.com/in/alexandergude'
    assert_includes same_as, 'https://github.com/agude'
    assert_includes same_as, 'https://bsky.app/profile/alexgude.com'
  end

  def test_generate_hash_includes_mastodon_with_instance
    config = @site_config.dup
    config['author'] = config['author'].merge(
      'mastodon' => 'alex',
      'mastodon_instance' => 'fosstodon.org'
    )
    doc = create_linktree_doc
    site = create_site(config)
    result = Jekyll::SEO::Generators::ProfilePageLdGenerator.generate_hash(doc, site)

    assert_includes result['mainEntity']['sameAs'], 'https://fosstodon.org/@alex'
  end

  def test_generate_hash_includes_name
    doc = create_linktree_doc(title: 'Linktree')
    site = create_site(@site_config)
    result = Jekyll::SEO::Generators::ProfilePageLdGenerator.generate_hash(doc, site)

    assert_equal 'Linktree', result['name']
  end

  def test_generate_hash_includes_description
    doc = create_linktree_doc(description: 'Links to find Alex online.')
    site = create_site(@site_config)
    result = Jekyll::SEO::Generators::ProfilePageLdGenerator.generate_hash(doc, site)

    assert_equal 'Links to find Alex online.', result['description']
  end

  def test_generate_hash_without_author
    config = @site_config.dup
    config.delete('author')
    doc = create_linktree_doc
    site = create_site(config)
    result = Jekyll::SEO::Generators::ProfilePageLdGenerator.generate_hash(doc, site)

    refute result.key?('mainEntity'), 'Missing author should omit mainEntity'
  end

  private

  def create_linktree_doc(title: 'Linktree', description: nil)
    data = {
      'layout' => 'default',
      'title' => title,
    }
    data['description'] = description if description

    create_doc(data, '/linktree/', 'Linktree content', nil, nil)
  end
end
