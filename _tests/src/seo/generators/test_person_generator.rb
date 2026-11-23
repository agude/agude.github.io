# frozen_string_literal: true

require_relative '../../../test_helper'

# Checks the ProfilePage and Person nodes produced from résumé documents.
class TestPersonLdGenerator < Minitest::Test
  BASE_URL = 'https://example.com'
  OWNER = {
    '@type' => 'Person', '@id' => "#{BASE_URL}/resume/#person", 'url' => "#{BASE_URL}/resume/",
  }.freeze

  def test_resume_describes_the_site_owner
    site = create_site(
      'url' => BASE_URL,
      'title' => 'Example',
      'logo' => '/headshot.jpg',
      'author' => {
        'name' => 'Alex Gude',
        'url' => '/resume/',
        'linkedin' => 'alexgude',
        'github' => 'agude',
        'bluesky' => 'example.com',
        'mastodon' => 'alex',
        'mastodon_instance' => 'fosstodon.org',
      },
    )
    doc = create_doc(
      {
        'layout' => 'resume',
        'title' => 'My&nbsp;Resume<br>Here',
        'description' => 'Page summary.',
        'job_title' => 'Staff Engineer',
        'experience' => [
          {
            'company' => 'Current Employer',
            'positions' => [
              { 'title' => 'Staff Engineer', 'dates' => '2023--Present' },
              { 'title' => 'Engineer', 'dates' => '2020--2023' },
            ],
          },
          { 'company' => 'Former Employer', 'positions' => [{ 'title' => 'Scientist', 'dates' => '2017--2020' }] },
        ],
        'education' => [
          { 'company' => 'University', 'positions' => [{ 'title' => 'PhD' }] },
          { 'company' => 'College', 'positions' => [{ 'title' => 'BA' }] },
        ],
        'skills' => { 'languages' => '<em>LaTeX</em>, Python', 'tools' => 'NumPy, Python' },
      },
      '/profile/',
    )

    university = { '@type' => 'EducationalOrganization', 'name' => 'University' }
    college = { '@type' => 'EducationalOrganization', 'name' => 'College' }
    expected = {
      '@context' => 'https://schema.org',
      '@type' => 'ProfilePage',
      '@id' => "#{BASE_URL}/profile/",
      'url' => "#{BASE_URL}/profile/",
      'name' => "My\u00A0Resume Here",
      'description' => 'Page summary.',
      'isPartOf' => { '@type' => 'WebSite', '@id' => "#{BASE_URL}/#website", 'name' => 'Example', 'url' => "#{BASE_URL}/" },
      'mainEntity' => OWNER.merge(
        'name' => 'Alex Gude',
        'jobTitle' => 'Staff Engineer',
        'image' => { '@type' => 'ImageObject', 'url' => "#{BASE_URL}/headshot.jpg" },
        'sameAs' => %w[https://www.linkedin.com/in/alexgude https://github.com/agude https://bsky.app/profile/example.com https://fosstodon.org/@alex],
        'worksFor' => { '@type' => 'Organization', 'name' => 'Current Employer' },
        'alumniOf' => [{ '@type' => 'Organization', 'name' => 'Former Employer' }, university, college],
        'hasOccupation' => [
          { '@type' => 'Role', 'hasOccupation' => { '@type' => 'Occupation', 'name' => 'Staff Engineer' }, 'startDate' => '2023' },
          { '@type' => 'Role', 'hasOccupation' => { '@type' => 'Occupation', 'name' => 'Engineer' }, 'startDate' => '2020', 'endDate' => '2023' },
          { '@type' => 'Role', 'hasOccupation' => { '@type' => 'Occupation', 'name' => 'Scientist' }, 'startDate' => '2017', 'endDate' => '2020' },
        ],
        'hasCredential' => [
          { '@type' => 'EducationalOccupationalCredential', 'credentialCategory' => 'degree', 'name' => 'PhD', 'recognizedBy' => university },
          { '@type' => 'EducationalOccupationalCredential', 'credentialCategory' => 'degree', 'name' => 'BA', 'recognizedBy' => college },
        ],
        'knowsAbout' => %w[LaTeX Python NumPy],
      ),
    }
    assert_equal expected, generate(doc, site)
  end

  def test_resume_omits_missing_or_empty_person_fields
    doc = create_doc({ 'layout' => 'resume', 'title' => 'Resume' }, '/resume/')
    site = create_site('url' => BASE_URL, 'author' => { 'url' => '/resume/' })

    assert_equal OWNER, generate(doc, site)['mainEntity']
    doc.data.merge!('experience' => [], 'education' => [], 'skills' => {}, 'job_title' => ' ')
    site.config['author']['mastodon'] = 'alex'
    assert_equal OWNER, generate(doc, site)['mainEntity']
  end

  def test_main_entity_without_author_url_raises
    doc = create_doc({ 'layout' => 'resume', 'title' => 'Resume' }, '/resume/')
    site = create_site('url' => BASE_URL, 'author' => { 'name' => 'Alex Gude' })

    error = assert_raises(Jekyll::Errors::FatalException) { generate(doc, site) }
    assert_includes error.message, 'author.url'
  end

  private

  def generate(doc, site)
    Jekyll::SEO::JsonLdInjector.generate_hash(doc, site)
  end
end
