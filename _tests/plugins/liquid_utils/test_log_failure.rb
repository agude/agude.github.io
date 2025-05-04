require_relative '../../test_helper'

class TestLiquidUtils < Minitest::Test

  # --- log_failure ---
  def test_log_failure_test_env_enabled
    site = create_site({ 'plugin_logging' => { 'TEST_TAG' => true } }) # Explicitly enable
    ctx = create_context({}, { site: site, page: create_doc({}, '/page.html') })
    output = LiquidUtils.log_failure(context: ctx, tag_type: "TEST_TAG", reason: "It broke", identifiers: { Key: "Val<>" })

    expected_comment = "<!-- TEST_TAG_FAILURE: Reason='It broke' Key='Val&lt;&gt;' SourcePage='page.html' -->"
    assert_equal expected_comment, output
    # We cannot easily test console output here
  end

  def test_log_failure_test_env_disabled_via_config
    site = create_site({ 'plugin_logging' => { 'TEST_TAG' => false } }) # Explicitly disable
    ctx = create_context({}, { site: site, page: create_doc({}, '/page.html') })
    output = LiquidUtils.log_failure(context: ctx, tag_type: "TEST_TAG", reason: "It broke", identifiers: {})

    assert_equal "", output # Should return empty string
  end

  def test_log_failure_test_env_disabled_by_default
    # Logging is disabled by default in helper, no need to override config
    site = create_site
    ctx = create_context({}, { site: site, page: create_doc({}, '/page.html') })
    output = LiquidUtils.log_failure(context: ctx, tag_type: "ANY_TAG", reason: "It broke", identifiers: {})

    assert_equal "", output # Should return empty string because helper disables it
  end

  def test_log_failure_production_env
    # Override helper default to enable logging, but set production env
    site = create_site({ 'environment' => 'production', 'plugin_logging' => { 'PROD_TAG' => true } })
    ctx = create_context({}, { site: site, page: create_doc({}, '/page.html') })
    output = LiquidUtils.log_failure(context: ctx, tag_type: "PROD_TAG", reason: "Prod issue", identifiers: {})

    assert_equal "", output # HTML comment should be disabled in production
    # We assume console logging still happens but can't easily test it here
  end

end
