# frozen_string_literal: true

require_relative '../../../test_helper'

# Tests for Jekyll::SEO::Generators::PersonLdGenerator module.
#
# Verifies that the generator correctly creates JSON-LD structured data for resume/about pages.
class TestPersonLdGenerator < Minitest::Test
  def setup
    @site_config = {
      'url' => 'https://alexgude.com',
      'baseurl' => '',
      'author' => {
        'name' => 'Alexander Gude',
        'email' => 'alex@example.com',
        'linkedin' => 'alexandergude',
        'github' => 'agude',
        'bluesky' => 'alexgude.com',
      },
    }
  end

  def test_generate_hash_basic_resume
    doc = create_resume_doc
    site = create_site(@site_config)
    result = Jekyll::SEO::Generators::PersonLdGenerator.generate_hash(doc, site)

    assert_equal 'https://schema.org', result['@context']
    assert_equal 'Person', result['@type']
    assert_equal 'Alexander Gude', result['name']
    assert_equal 'https://alexgude.com/resume/', result['url']
  end

  def test_generate_hash_includes_job_title
    doc = create_resume_doc(job_title: 'Staff Machine Learning Engineer')
    site = create_site(@site_config)
    result = Jekyll::SEO::Generators::PersonLdGenerator.generate_hash(doc, site)

    assert_equal 'Staff Machine Learning Engineer', result['jobTitle']
  end

  def test_generate_hash_includes_works_for
    doc = create_resume_doc(works_for: 'Cash App')
    site = create_site(@site_config)
    result = Jekyll::SEO::Generators::PersonLdGenerator.generate_hash(doc, site)

    expected_org = { '@type' => 'Organization', 'name' => 'Cash App' }
    assert_equal expected_org, result['worksFor']
  end

  def test_generate_hash_includes_description
    doc = create_resume_doc(description: 'A machine learning engineer.')
    site = create_site(@site_config)
    result = Jekyll::SEO::Generators::PersonLdGenerator.generate_hash(doc, site)

    assert_equal 'A machine learning engineer.', result['description']
  end

  def test_generate_hash_includes_same_as_links
    doc = create_resume_doc
    site = create_site(@site_config)
    result = Jekyll::SEO::Generators::PersonLdGenerator.generate_hash(doc, site)

    assert result.key?('sameAs'), 'Should include sameAs links'
    assert_includes result['sameAs'], 'https://www.linkedin.com/in/alexandergude'
    assert_includes result['sameAs'], 'https://github.com/agude'
    assert_includes result['sameAs'], 'https://bsky.app/profile/alexgude.com'
  end

  def test_generate_hash_includes_mastodon_with_instance
    config = @site_config.dup
    config['author'] = config['author'].merge(
      'mastodon' => 'alex',
      'mastodon_instance' => 'fosstodon.org'
    )
    doc = create_resume_doc
    site = create_site(config)
    result = Jekyll::SEO::Generators::PersonLdGenerator.generate_hash(doc, site)

    assert_includes result['sameAs'], 'https://fosstodon.org/@alex'
  end

  def test_generate_hash_omits_mastodon_without_instance
    config = @site_config.dup
    config['author'] = config['author'].merge('mastodon' => 'alex')
    doc = create_resume_doc
    site = create_site(config)
    result = Jekyll::SEO::Generators::PersonLdGenerator.generate_hash(doc, site)

    refute result['sameAs'].any? { |link| link.include?('mastodon') },
           'Mastodon without instance should be omitted'
  end

  def test_generate_hash_without_social_profiles
    config = {
      'url' => 'https://alexgude.com',
      'baseurl' => '',
      'author' => { 'name' => 'Alexander Gude' },
    }
    doc = create_resume_doc
    site = create_site(config)
    result = Jekyll::SEO::Generators::PersonLdGenerator.generate_hash(doc, site)

    refute result.key?('sameAs'), 'No social profiles should omit sameAs'
  end

  def test_generate_hash_without_author_name
    config = {
      'url' => 'https://alexgude.com',
      'baseurl' => '',
      'author' => {},
    }
    doc = create_resume_doc
    site = create_site(config)
    result = Jekyll::SEO::Generators::PersonLdGenerator.generate_hash(doc, site)

    refute result.key?('name'), 'Missing author name should omit name'
  end

  def test_generate_hash_without_job_title
    doc = create_resume_doc
    site = create_site(@site_config)
    result = Jekyll::SEO::Generators::PersonLdGenerator.generate_hash(doc, site)

    refute result.key?('jobTitle'), 'Missing job_title should omit field'
  end

  def test_generate_hash_without_works_for
    doc = create_resume_doc
    site = create_site(@site_config)
    result = Jekyll::SEO::Generators::PersonLdGenerator.generate_hash(doc, site)

    refute result.key?('worksFor'), 'Missing works_for should omit field'
  end

  private

  def create_resume_doc(job_title: nil, works_for: nil, description: nil)
    data = {
      'layout' => 'resume',
      'title' => 'Resume',
    }
    data['job_title'] = job_title if job_title
    data['works_for'] = works_for if works_for
    data['description'] = description if description

    create_doc(data, '/resume/', 'Resume content', nil, nil)
  end
end
