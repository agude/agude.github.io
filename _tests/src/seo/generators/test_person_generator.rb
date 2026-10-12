# frozen_string_literal: true

require_relative '../../../test_helper'

# Tests for Jekyll::SEO::Generators::PersonLdGenerator module.
#
# The resume is the site owner's profile page: a ProfilePage whose
# mainEntity is the owner's Person node. Google's Article guidance points
# author.url at a page identifying the author, and an internal profile page
# should carry ProfilePage markup. Page-level text (name, description) stays
# on the page node; the resume facts live on the Person.
class TestPersonLdGenerator < Minitest::Test
  def setup
    @site_config = {
      'url' => 'https://alexgude.com',
      'baseurl' => '',
      'author' => {
        'name' => 'Alexander Gude',
        'url' => '/resume/',
        'email' => 'alex@example.com',
        'linkedin' => 'alexandergude',
        'github' => 'agude',
        'bluesky' => 'alexgude.com',
      },
    }
  end

  # --- Page node ---

  def test_generate_hash_is_profile_page
    doc = create_resume_doc
    site = create_site(@site_config)
    result = Jekyll::SEO::Generators::PersonLdGenerator.generate_hash(doc, site)

    assert_equal 'https://schema.org', result['@context']
    assert_equal 'ProfilePage', result['@type']
    assert_equal 'https://alexgude.com/resume/', result['@id']
    assert_equal 'https://alexgude.com/resume/', result['url']
    assert_equal 'Resume', result['name']
  end

  def test_generate_hash_page_carries_page_description
    doc = create_resume_doc(description: "Alexander Gude's Resume.")
    site = create_site(@site_config)
    result = Jekyll::SEO::Generators::PersonLdGenerator.generate_hash(doc, site)

    assert_equal "Alexander Gude's Resume.", result['description']
  end

  def test_generate_hash_page_is_part_of_website
    doc = create_resume_doc
    site = create_site(@site_config.merge('title' => 'Alex Gude'))
    result = Jekyll::SEO::Generators::PersonLdGenerator.generate_hash(doc, site)

    assert_equal 'https://alexgude.com/#website', result.dig('isPartOf', '@id')
  end

  # --- mainEntity: the site owner ---

  def test_main_entity_is_site_owner_person
    doc = create_resume_doc
    site = create_site(@site_config)
    person = generate_person(doc, site)

    assert_equal 'Person', person['@type']
    assert_equal 'Alexander Gude', person['name']
  end

  def test_main_entity_includes_job_title
    doc = create_resume_doc(job_title: 'Staff Machine Learning Engineer')
    site = create_site(@site_config)
    result = generate_person(doc, site)

    assert_equal 'Staff Machine Learning Engineer', result['jobTitle']
  end

  def test_main_entity_includes_works_for_from_experience
    experience = [{ 'company' => 'Cash App', 'positions' => [{ 'title' => 'Engineer', 'dates' => '2023--Present' }] }]
    doc = create_resume_doc(experience: experience)
    site = create_site(@site_config)
    result = generate_person(doc, site)

    works_for = result['worksFor']
    assert_equal 'Organization', works_for['@type']
    assert_equal 'Cash App', works_for['name']
  end

  # The resume's description describes the page ("Alexander Gude's
  # Resume. ..."), not the person, so it must not land on the Person node.
  def test_main_entity_ignores_page_description
    doc = create_resume_doc(description: "Alexander Gude's Resume.")
    site = create_site(@site_config)
    person = generate_person(doc, site)

    refute person.key?('description'), 'Page description should not describe the Person'
  end

  # The page URL and author.url differ here so an implementation that
  # ignores the config and reuses document.url cannot pass.
  def test_main_entity_uses_configured_identity_url_as_id
    config = @site_config.merge('author' => @site_config['author'].merge('url' => '/resume/'))
    doc = create_resume_doc(url: '/about/')
    site = create_site(config)
    result = Jekyll::SEO::Generators::PersonLdGenerator.generate_hash(doc, site)

    assert_equal 'https://alexgude.com/about/', result['@id'], 'Page @id is the page URL'
    assert_equal 'https://alexgude.com/resume/#person', result.dig('mainEntity', '@id')
    assert_equal 'https://alexgude.com/resume/', result.dig('mainEntity', 'url')
  end

  def test_main_entity_without_author_url_raises
    config = @site_config.merge('author' => @site_config['author'].except('url'))
    site = create_site(config)

    assert_raises(Jekyll::Errors::FatalException) { generate_person(create_resume_doc, site) }
  end

  def test_main_entity_includes_same_as_links
    doc = create_resume_doc
    site = create_site(@site_config)
    result = generate_person(doc, site)

    assert result.key?('sameAs'), 'Should include sameAs links'
    assert_includes result['sameAs'], 'https://www.linkedin.com/in/alexandergude'
    assert_includes result['sameAs'], 'https://github.com/agude'
    assert_includes result['sameAs'], 'https://bsky.app/profile/alexgude.com'
  end

  def test_main_entity_includes_mastodon_with_instance
    config = @site_config.dup
    config['author'] = config['author'].merge(
      'mastodon' => 'alex',
      'mastodon_instance' => 'fosstodon.org',
    )
    doc = create_resume_doc
    site = create_site(config)
    result = generate_person(doc, site)

    assert_includes result['sameAs'], 'https://fosstodon.org/@alex'
  end

  def test_main_entity_omits_mastodon_without_instance
    config = @site_config.dup
    config['author'] = config['author'].merge('mastodon' => 'alex')
    doc = create_resume_doc
    site = create_site(config)
    result = generate_person(doc, site)

    refute result['sameAs'].any? { |link| link.include?('mastodon') },
           'Mastodon without instance should be omitted'
  end

  def test_main_entity_without_social_profiles
    config = {
      'url' => 'https://alexgude.com',
      'baseurl' => '',
      'author' => { 'name' => 'Alexander Gude', 'url' => '/resume/' },
    }
    doc = create_resume_doc
    site = create_site(config)
    result = generate_person(doc, site)

    refute result.key?('sameAs'), 'No social profiles should omit sameAs'
  end

  def test_main_entity_without_author_name
    config = {
      'url' => 'https://alexgude.com',
      'baseurl' => '',
      'author' => { 'url' => '/resume/' },
    }
    doc = create_resume_doc
    site = create_site(config)
    result = generate_person(doc, site)

    refute result.key?('name'), 'Missing author name should omit name'
  end

  def test_main_entity_without_job_title
    doc = create_resume_doc
    site = create_site(@site_config)
    result = generate_person(doc, site)

    refute result.key?('jobTitle'), 'Missing job_title should omit field'
  end

  def test_main_entity_without_works_for_when_no_experience
    doc = create_resume_doc
    site = create_site(@site_config)
    result = generate_person(doc, site)

    refute result.key?('worksFor'), 'Missing experience should omit worksFor field'
  end

  # --- hasOccupation with Role objects ---

  def test_has_occupation_uses_role_type
    experience = [
      { 'company' => 'Cash App', 'positions' => [{ 'title' => 'Engineer', 'dates' => '2023--Present' }] },
    ]
    doc = create_resume_doc(experience: experience)
    site = create_site(@site_config)
    result = generate_person(doc, site)

    occupations = result['hasOccupation']
    assert occupations.is_a?(Array), 'hasOccupation should be an array of Role objects'
    assert_equal 'Role', occupations.first['@type']
  end

  def test_has_occupation_role_has_nested_occupation
    experience = [
      { 'company' => 'Cash App', 'positions' => [{ 'title' => 'Staff Engineer', 'dates' => '2023--Present' }] },
    ]
    doc = create_resume_doc(experience: experience)
    site = create_site(@site_config)
    result = generate_person(doc, site)

    role = result['hasOccupation'].first
    occupation = role['hasOccupation']
    assert_equal 'Occupation', occupation['@type']
    assert_equal 'Staff Engineer', occupation['name']
  end

  def test_has_occupation_role_parses_start_date
    experience = [
      { 'company' => 'Cash App', 'positions' => [{ 'title' => 'Engineer', 'dates' => '2023--Present' }] },
    ]
    doc = create_resume_doc(experience: experience)
    site = create_site(@site_config)
    result = generate_person(doc, site)

    role = result['hasOccupation'].first
    assert_equal '2023', role['startDate']
  end

  def test_has_occupation_role_omits_end_date_for_current_job
    experience = [
      { 'company' => 'Cash App', 'positions' => [{ 'title' => 'Engineer', 'dates' => '2023--Present' }] },
    ]
    doc = create_resume_doc(experience: experience)
    site = create_site(@site_config)
    result = generate_person(doc, site)

    role = result['hasOccupation'].first
    refute role.key?('endDate'), 'Current job should not have endDate'
  end

  def test_has_occupation_role_includes_end_date_for_past_job
    experience = [
      { 'company' => 'Intuit', 'positions' => [{ 'title' => 'Data Scientist', 'dates' => '2017--2020' }] },
    ]
    doc = create_resume_doc(experience: experience)
    site = create_site(@site_config)
    result = generate_person(doc, site)

    role = result['hasOccupation'].first
    assert_equal '2020', role['endDate']
  end

  def test_has_occupation_includes_all_positions_from_all_companies
    experience = [
      {
        'company' => 'Cash App',
        'positions' => [
          { 'title' => 'Senior Staff Engineer', 'dates' => '2023--Present' },
          { 'title' => 'Staff Engineer', 'dates' => '2020--2023' },
        ],
      },
      {
        'company' => 'Intuit',
        'positions' => [{ 'title' => 'Data Scientist', 'dates' => '2017--2020' }],
      },
    ]
    doc = create_resume_doc(experience: experience)
    site = create_site(@site_config)
    result = generate_person(doc, site)

    occupations = result['hasOccupation']
    assert_equal 3, occupations.length, 'Should include all positions from all companies'

    titles = occupations.map { |r| r.dig('hasOccupation', 'name') }
    assert_includes titles, 'Senior Staff Engineer'
    assert_includes titles, 'Staff Engineer'
    assert_includes titles, 'Data Scientist'
  end

  # --- alumniOf includes former employers and schools ---

  def test_alumni_of_contains_educational_organizations
    education = [
      { 'company' => 'University of Minnesota', 'positions' => [{ 'title' => 'PhD', 'dates' => '2009--2015' }] },
    ]
    doc = create_resume_doc(education: education)
    site = create_site(@site_config)
    result = generate_person(doc, site)

    alumni_of = result['alumniOf']
    assert alumni_of.is_a?(Array)
    assert_equal 'EducationalOrganization', alumni_of.first['@type']
    assert_equal 'University of Minnesota', alumni_of.first['name']
  end

  def test_alumni_of_includes_former_employers
    experience = [
      { 'company' => 'Cash App', 'positions' => [{ 'title' => 'Engineer', 'dates' => '2023--Present' }] },
      { 'company' => 'Intuit', 'positions' => [{ 'title' => 'Data Scientist', 'dates' => '2017--2020' }] },
      { 'company' => 'Lab41', 'positions' => [{ 'title' => 'Data Scientist', 'dates' => '2015--2017' }] },
    ]
    doc = create_resume_doc(experience: experience)
    site = create_site(@site_config)
    result = generate_person(doc, site)

    alumni_of = result['alumniOf']
    names = alumni_of.map { |a| a['name'] }
    assert_includes names, 'Intuit'
    assert_includes names, 'Lab41'
    refute_includes names, 'Cash App', 'Current employer should not be in alumniOf'
  end

  def test_alumni_of_former_employers_are_organization_type
    experience = [
      { 'company' => 'Cash App', 'positions' => [{ 'title' => 'Engineer', 'dates' => '2023--Present' }] },
      { 'company' => 'Intuit', 'positions' => [{ 'title' => 'Data Scientist', 'dates' => '2017--2020' }] },
    ]
    doc = create_resume_doc(experience: experience)
    site = create_site(@site_config)
    result = generate_person(doc, site)

    intuit = result['alumniOf'].find { |a| a['name'] == 'Intuit' }
    assert_equal 'Organization', intuit['@type']
  end

  def test_alumni_of_includes_all_schools
    education = [
      { 'company' => 'University of Minnesota', 'positions' => [{ 'title' => 'PhD', 'dates' => '2009--2015' }] },
      { 'company' => 'UC Berkeley', 'positions' => [{ 'title' => 'BA', 'dates' => '2004--2008' }] },
    ]
    doc = create_resume_doc(education: education)
    site = create_site(@site_config)
    result = generate_person(doc, site)

    alumni_of = result['alumniOf']
    assert_equal 2, alumni_of.length
    names = alumni_of.map { |a| a['name'] }
    assert_includes names, 'University of Minnesota'
    assert_includes names, 'UC Berkeley'
  end

  def test_alumni_of_combines_former_employers_and_schools
    experience = [
      { 'company' => 'Cash App', 'positions' => [{ 'title' => 'Engineer', 'dates' => '2023--Present' }] },
      { 'company' => 'Intuit', 'positions' => [{ 'title' => 'Data Scientist', 'dates' => '2017--2020' }] },
    ]
    education = [
      { 'company' => 'University of Minnesota', 'positions' => [{ 'title' => 'PhD', 'dates' => '2009--2015' }] },
    ]
    doc = create_resume_doc(experience: experience, education: education)
    site = create_site(@site_config)
    result = generate_person(doc, site)

    alumni_of = result['alumniOf']
    assert_equal 2, alumni_of.length
    names = alumni_of.map { |a| a['name'] }
    assert_includes names, 'Intuit'
    assert_includes names, 'University of Minnesota'
  end

  # --- Credentials ---

  def test_has_credential_for_degrees
    education = [
      { 'company' => 'University of Minnesota', 'positions' => [{ 'title' => 'PhD, Physics', 'dates' => '2009--2015' }] },
    ]
    doc = create_resume_doc(education: education)
    site = create_site(@site_config)
    result = generate_person(doc, site)

    credentials = result['hasCredential']
    assert credentials.is_a?(Array)
    cred = credentials.first
    assert_equal 'EducationalOccupationalCredential', cred['@type']
    assert_equal 'PhD, Physics', cred['name']
    assert_equal 'degree', cred['credentialCategory']
  end

  def test_has_credential_includes_recognized_by
    education = [
      { 'company' => 'University of Minnesota', 'positions' => [{ 'title' => 'PhD', 'dates' => '2009--2015' }] },
    ]
    doc = create_resume_doc(education: education)
    site = create_site(@site_config)
    result = generate_person(doc, site)

    cred = result['hasCredential'].first
    recognized_by = cred['recognizedBy']
    assert_equal 'EducationalOrganization', recognized_by['@type']
    assert_equal 'University of Minnesota', recognized_by['name']
  end

  # --- knowsAbout ---

  def test_knows_about_extracts_skills
    skills = { 'languages' => 'Python, Scala, SQL', 'tools' => 'NumPy, Pandas' }
    doc = create_resume_doc(skills: skills)
    site = create_site(@site_config)
    result = generate_person(doc, site)

    knows = result['knowsAbout']
    assert_includes knows, 'Python'
    assert_includes knows, 'Scala'
    assert_includes knows, 'NumPy'
    assert_includes knows, 'Pandas'
  end

  def test_knows_about_strips_html
    skills = { 'languages' => '<span class="latex">LaTeX</span>, Python' }
    doc = create_resume_doc(skills: skills)
    site = create_site(@site_config)
    result = generate_person(doc, site)

    knows = result['knowsAbout']
    assert_includes knows, 'LaTeX'
    assert_includes knows, 'Python'
    refute knows.any? { |k| k.include?('<') }, 'Should not contain HTML'
  end

  # --- Image ---

  def test_main_entity_includes_image_from_site_logo
    config = @site_config.merge('logo' => '/files/headshot.jpg')
    doc = create_resume_doc
    site = create_site(config)
    result = generate_person(doc, site)

    assert result.key?('image'), 'Should include image from site logo'
    image = result['image']
    assert_equal 'ImageObject', image['@type']
    assert_equal 'https://alexgude.com/files/headshot.jpg', image['url']
  end

  def test_main_entity_omits_image_without_logo
    doc = create_resume_doc
    site = create_site(@site_config)
    result = generate_person(doc, site)

    refute result.key?('image'), 'Missing logo should omit image'
  end

  # Titles may contain <br> and &nbsp; for on-page display. JSON-LD names
  # are plain text.
  def test_generate_hash_page_name_is_plain_text
    doc = create_resume_doc
    doc.data['title'] = 'Clever(ly&nbsp;Terrible)<br>Code'
    result = Jekyll::SEO::Generators::PersonLdGenerator.generate_hash(doc, create_site(@site_config))
    assert_equal "Clever(ly\u00A0Terrible) Code", result['name']
  end

  private

  def generate_person(doc, site)
    Jekyll::SEO::Generators::PersonLdGenerator.generate_hash(doc, site)['mainEntity']
  end

  def create_resume_doc(job_title: nil, experience: nil, education: nil, skills: nil, description: nil,
                        url: '/resume/')
    data = {
      'layout' => 'resume',
      'title' => 'Resume',
    }
    data['job_title'] = job_title if job_title
    data['experience'] = experience if experience
    data['education'] = education if education
    data['skills'] = skills if skills
    data['description'] = description if description

    create_doc(data, url, 'Resume content', nil, nil)
  end
end
