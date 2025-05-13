# _plugins/utils/plugin_logger_utils.rb
require 'cgi'
require 'jekyll'

module PluginLoggerUtils
  LOG_LEVEL_MAP = {
    debug: 0,
    info:  1,
    warn:  2,
    error: 3,
  }.freeze
  # Ensure DEFAULT_LOG_LEVEL_SYMBOL is a key in LOG_LEVEL_MAP
  DEFAULT_MESSAGE_LEVEL_SYMBOL = :warn
  DEFAULT_SITE_CONSOLE_LEVEL_STRING = "warn".freeze


  def self.log_liquid_failure(context:, tag_type:, reason:, identifiers: {}, level: DEFAULT_MESSAGE_LEVEL_SYMBOL)
    # 1. Initial validation for context and site
    unless context && (site = context.registers[:site])
      log_msg = "[PLUGIN LOGGER ERROR] Context or Site unavailable. Original Call: #{tag_type} - #{level}: #{reason}"
      if defined?(Jekyll.logger) && Jekyll.logger.respond_to?(:error)
        Jekyll.logger.error("PluginLogger:", log_msg)
      else
        STDERR.puts log_msg
      end
      return "" # Return empty string as no HTML comment can be formed
    end

    # 2. Check if logging is enabled for this specific tag_type
    plugin_logging_config = site.config['plugin_logging'] || {}
    tag_logging_enabled = (plugin_logging_config[tag_type.to_s] == true) # Explicitly true

    return "" unless tag_logging_enabled # Do nothing if this tag_type is disabled

    # 3. Prepare message content (done once, used by both console and HTML)
    message_level_symbol = LOG_LEVEL_MAP.key?(level) ? level : DEFAULT_MESSAGE_LEVEL_SYMBOL
    page_path = context.registers[:page] ? context.registers[:page]['path'] : 'unknown_page'
    identifier_string = identifiers.map { |key, value| "#{key}='#{CGI.escapeHTML(value.to_s)}'" }.join(' ')
    safe_tag_type = CGI.escapeHTML(tag_type.to_s)
    safe_reason = CGI.escapeHTML(reason.to_s)
    log_message_base = "[#{message_level_symbol.to_s.upcase}] #{safe_tag_type}_FAILURE: Reason='#{safe_reason}' #{identifier_string} SourcePage='#{page_path}'".strip

    # 4. Console Logging (respects global plugin_log_level)
    site_console_log_level_str = site.config['plugin_log_level']&.downcase || DEFAULT_SITE_CONSOLE_LEVEL_STRING
    site_console_log_level_val = LOG_LEVEL_MAP[site_console_log_level_str.to_sym] || LOG_LEVEL_MAP[DEFAULT_MESSAGE_LEVEL_SYMBOL]
    message_log_level_val = LOG_LEVEL_MAP[message_level_symbol]

    if message_log_level_val >= site_console_log_level_val
      if defined?(Jekyll.logger) && Jekyll.logger.respond_to?(message_level_symbol)
        Jekyll.logger.public_send(message_level_symbol, "PluginLiquid:", log_message_base)
      else
        # Fallback puts includes the level from the message itself
        puts "[PLUGIN_LIQUID_LOG] #{log_message_base}"
      end
    end

    # 5. HTML Comment Logging (based on environment, not global plugin_log_level)
    html_output_comment = ""
    environment = site.config['environment'] || 'development'
    is_production = (environment == 'production')

    unless is_production
      html_output_comment = "<!-- #{log_message_base} -->"
    end

    html_output_comment # Return HTML comment (or "" if in production)
  end
end
