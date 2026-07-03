# frozen_string_literal: true

require_relative '../../test_helper'

# Tests for Jekyll::SEO::PersonJsonLdBuilder — person/resume schema methods.
# rubocop:disable Style/SymbolProc -- builder DSL requires block form
class TestPersonJsonLdBuilder < Minitest::Test
  def setup
    @site_config = {
      'url' => 'https://example.com',
      'baseurl' => '/blog',
      'title' => 'Test Site',
      'logo' => '/images/logo.jpg',
      'author' => {
        'name' => 'Site Author',
        'first' => 'Site',
        'last' => 'Author',
        'alternate_names' => ['Pseudonym'],
        'honorific_prefix' => 'Dr.',
        'pronouns' => 'they/them',
        'gender' => 'https://schema.org/Male',
        'linkedin' => 'testuser',
        'github' => 'testuser',
      },
    }
    @site = create_site(@site_config)
  end

  def test_build_creates_person_builder_instance
    yielded = nil
    Jekyll::SEO::PersonJsonLdBuilder.build('Person') do |builder|
      yielded = builder
    end
    assert_instance_of Jekyll::SEO::PersonJsonLdBuilder, yielded
  end

  def test_inherits_json_ld_builder_methods
    result = Jekyll::SEO::PersonJsonLdBuilder.build('Person', site: @site) do |schema|
      schema.name 'Test Person'
      schema.url '/about/'
    end
    assert_equal 'Test Person', result['name']
    assert_equal 'https://example.com/blog/about/', result['url']
  end

  def test_job_title
    result = Jekyll::SEO::PersonJsonLdBuilder.build('Person') do |schema|
      schema.job_title 'Staff Engineer'
    end
    assert_equal 'Staff Engineer', result['jobTitle']
  end

  def test_given_name_and_family_name
    result = Jekyll::SEO::PersonJsonLdBuilder.build('Person') do |schema|
      schema.given_name 'Jane'
      schema.family_name 'Doe'
    end
    assert_equal 'Jane', result['givenName']
    assert_equal 'Doe', result['familyName']
  end

  def test_honorific_prefix
    result = Jekyll::SEO::PersonJsonLdBuilder.build('Person') do |schema|
      schema.honorific_prefix 'Dr.'
    end
    assert_equal 'Dr.', result['honorificPrefix']
  end

  def test_pronouns
    result = Jekyll::SEO::PersonJsonLdBuilder.build('Person') do |schema|
      schema.pronouns 'they/them'
    end
    assert_equal 'they/them', result['pronouns']
  end

  def test_gender
    result = Jekyll::SEO::PersonJsonLdBuilder.build('Person') do |schema|
      schema.gender 'https://schema.org/Male'
    end
    assert_equal 'https://schema.org/Male', result['gender']
  end

  def test_works_for
    result = Jekyll::SEO::PersonJsonLdBuilder.build('Person') do |schema|
      schema.works_for 'Acme Corp'
    end
    expected = { '@type' => 'Organization', 'name' => 'Acme Corp' }
    assert_equal expected, result['worksFor']
  end

  def test_works_for_nil_not_added
    result = Jekyll::SEO::PersonJsonLdBuilder.build('Person') do |schema|
      schema.works_for nil
    end
    refute result.key?('worksFor')
  end

  def test_alumni_of_education
    education = [{ 'company' => 'MIT', 'positions' => [] }]
    result = Jekyll::SEO::PersonJsonLdBuilder.build('Person') do |schema|
      schema.alumni_of([], education)
    end
    assert_equal 1, result['alumniOf'].length
    assert_equal 'EducationalOrganization', result['alumniOf'].first['@type']
    assert_equal 'MIT', result['alumniOf'].first['name']
  end

  def test_alumni_of_former_employers_skips_current
    experience = [
      { 'company' => 'Current Co' },
      { 'company' => 'Previous Co' },
    ]
    result = Jekyll::SEO::PersonJsonLdBuilder.build('Person') do |schema|
      schema.alumni_of(experience, [])
    end
    names = result['alumniOf'].map { |a| a['name'] }
    refute_includes names, 'Current Co'
    assert_includes names, 'Previous Co'
  end

  def test_has_occupation
    experience = [
      {
        'company' => 'Acme',
        'positions' => [{ 'title' => 'Engineer', 'dates' => '2020--Present' }],
      },
    ]
    result = Jekyll::SEO::PersonJsonLdBuilder.build('Person') do |schema|
      schema.has_occupation experience
    end
    roles = result['hasOccupation']
    assert_equal 1, roles.length
    assert_equal 'Role', roles.first['@type']
    assert_equal 'Engineer', roles.first['hasOccupation']['name']
  end

  def test_has_credential
    education = [
      {
        'company' => 'MIT',
        'positions' => [{ 'title' => 'B.S. Computer Science' }],
      },
    ]
    result = Jekyll::SEO::PersonJsonLdBuilder.build('Person') do |schema|
      schema.has_credential education
    end
    creds = result['hasCredential']
    assert_equal 1, creds.length
    assert_equal 'B.S. Computer Science', creds.first['name']
    assert_equal 'MIT', creds.first['recognizedBy']['name']
  end

  def test_knows_about
    skills = { 'languages' => 'Ruby, Python', 'tools' => 'Git, Docker' }
    result = Jekyll::SEO::PersonJsonLdBuilder.build('Person') do |schema|
      schema.knows_about skills
    end
    assert_includes result['knowsAbout'], 'Ruby'
    assert_includes result['knowsAbout'], 'Docker'
  end

  def test_social_links_from_site
    result = Jekyll::SEO::PersonJsonLdBuilder.build('Person', site: @site) do |schema|
      schema.social_links_from_site
    end
    assert_includes result['sameAs'], 'https://www.linkedin.com/in/testuser'
    assert_includes result['sameAs'], 'https://github.com/testuser'
  end

  def test_main_entity_person_with_social
    result = Jekyll::SEO::PersonJsonLdBuilder.build('ProfilePage', site: @site) do |schema|
      schema.main_entity_person_with_social
    end
    main = result['mainEntity']
    assert_equal 'Person', main['@type']
    assert_equal 'Site Author', main['name']
    assert_includes main['sameAs'], 'https://www.linkedin.com/in/testuser'
  end

  def test_alternate_names
    result = Jekyll::SEO::PersonJsonLdBuilder.build('Person') do |schema|
      schema.alternate_names ['Pen Name', 'Other Name']
    end
    assert_equal ['Pen Name', 'Other Name'], result['alternateName']
  end

  def test_author_identity_from_site
    result = Jekyll::SEO::PersonJsonLdBuilder.build('Person', site: @site) do |schema|
      schema.author_identity_from_site
    end
    assert_equal 'Site Author', result['name']
    assert_equal 'Site', result['givenName']
    assert_equal 'Author', result['familyName']
    assert_equal 'Dr.', result['honorificPrefix']
    assert_equal 'they/them', result['pronouns']
    assert_equal 'https://schema.org/Male', result['gender']
    assert_equal ['Pseudonym'], result['alternateName']
  end
end
# rubocop:enable Style/SymbolProc
