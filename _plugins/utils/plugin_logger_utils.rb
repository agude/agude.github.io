# _plugins/utils/plugin_logger_utils.rb
require 'cgi'
require 'jekyll'

module PluginLoggerUtils

  # Logs a failure message from a Liquid context (Tags/Filters).
  # Behavior depends on environment and _config.yml settings.
  # - Console logging: Uses Jekyll.logger.warn if available, otherwise falls back to puts.
  #   Enabled by default unless 'plugin_logging'.'TAG_TYPE' is false.
  # - HTML comment: Output into the rendered page.
  #   Enabled by default in non-production environments, disabled in production,
  #   unless 'plugin_logging'.'TAG_TYPE' is false.
  #
  # @param context [Liquid::Context] The current Liquid context.
  # @param tag_type [String] A string identifying the source/type of the log (e.g., "MY_TAG_ERROR").
  # @param reason [String] A description of the failure.
  # @param identifiers [Hash] Optional key-value pairs for additional context in the log.
  # @return [String] An HTML comment string if HTML logging is active, otherwise an empty string.
  def self.log_liquid_failure(context:, tag_type:, reason:, identifiers: {})
    # Ensure context and site are available
    unless context && (site = context.registers[:site])
      log_msg = "[PLUGIN LOGGER ERROR] Context or Site unavailable for logging. Original Call: #{tag_type} - #{reason}"
      if defined?(Jekyll.logger) && Jekyll.logger.respond_to?(:error)
        Jekyll.logger.error("PluginLogger:", log_msg) # Use a distinct prefix for internal logger errors
      else
        STDERR.puts log_msg # Use STDERR for logger internal errors
      end
      return "" # Cannot proceed with normal logging
    end

    environment = site.config['environment'] || 'development'
    is_production = (environment == 'production')

    log_setting_for_tag = site.config.dig('plugin_logging', tag_type.to_s)
    logging_enabled_for_tag = (log_setting_for_tag != false)

    base_log_console = true
    base_log_html = !is_production

    do_console_log = logging_enabled_for_tag && base_log_console
    do_html_log = logging_enabled_for_tag && base_log_html

    html_output_comment = ""

    if do_console_log || do_html_log
      page_path = context.registers[:page] ? context.registers[:page]['path'] : 'unknown_page'
      identifier_string = identifiers.map { |key, value| "#{key}='#{CGI.escapeHTML(value.to_s)}'" }.join(' ')

      safe_tag_type = CGI.escapeHTML(tag_type.to_s)
      safe_reason = CGI.escapeHTML(reason.to_s)

      log_message_base = "#{safe_tag_type}_FAILURE: Reason='#{safe_reason}' #{identifier_string} SourcePage='#{page_path}'".strip

      if do_console_log
        if defined?(Jekyll.logger) && Jekyll.logger.respond_to?(:warn)
          Jekyll.logger.warn("PluginLiquid:", log_message_base) # Prefix for Liquid context logs
        else
          puts "[PLUGIN_LIQUID_LOG] #{log_message_base}" # Fallback
        end
      end

      if do_html_log
        html_output_comment = "<!-- #{log_message_base} -->"
      end
    end

    html_output_comment
  end

end
