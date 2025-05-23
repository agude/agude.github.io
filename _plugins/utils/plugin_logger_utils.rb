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
  DEFAULT_MESSAGE_LEVEL_SYMBOL = :warn
  DEFAULT_SITE_CONSOLE_LEVEL_STRING = "warn".freeze

  # Centralized logging for Liquid tags/filters.
  # Handles console logging (respecting site.config['plugin_log_level'])
  # and HTML comment logging (for non-production environments).
  def self.log_liquid_failure(context:, tag_type:, reason:, identifiers: {}, level: DEFAULT_MESSAGE_LEVEL_SYMBOL)

    site_from_context = nil
    can_get_site_config = false

    # --- 1. Validate Context and Site Configuration Access ---
    # Ensure that context, site, and site.config are accessible for logging configuration.
    if context && context.respond_to?(:registers) && context.registers.is_a?(Hash)
      site_from_context = context.registers[:site]
      if site_from_context && site_from_context.respond_to?(:config) && site_from_context.config.is_a?(Hash)
        can_get_site_config = true
      end
    end

    unless can_get_site_config
      # Fallback if essential context/site/config is broken. Log directly to STDERR if Jekyll.logger is unavailable.
      log_msg = "[PLUGIN LOGGER ERROR] Context, Site, or Site Config unavailable for logging. Original Call: #{tag_type} - #{level}: #{reason}"
      if defined?(Jekyll.logger) && Jekyll.logger.respond_to?(:error)
        Jekyll.logger.error("PluginLogger:", log_msg)
      else
        STDERR.puts log_msg # Absolute fallback
      end
      return "" # Cannot generate HTML comment without site config.
    end

    site = site_from_context

    # --- 2. Check if Logging is Enabled for this Tag Type ---
    plugin_logging_config = site.config['plugin_logging'] || {}
    tag_logging_enabled = (plugin_logging_config[tag_type.to_s] == true) # Explicitly check for true

    # Determine site environment for HTML comment generation
    site_env_raw = site.config['environment']
    site_env = site_env_raw || 'development' # Default to development if not set
    is_prod = (site_env.to_s.downcase == 'production')

    return "" unless tag_logging_enabled # Do nothing further if this tag_type's logging is disabled.

    # --- 3. Prepare Log Message Content ---
    # Standardize message level and gather page path for context.
    message_level_symbol = LOG_LEVEL_MAP.key?(level) ? level : DEFAULT_MESSAGE_LEVEL_SYMBOL

    page_from_context = context.registers[:page]
    page_path = 'unknown_page' # Default if page or path is not available
    if page_from_context && page_from_context.respond_to?(:[]) && page_from_context['path']
      page_path = page_from_context['path']
    elsif page_from_context # Page object exists but path might be missing or not a hash access
      page_path = "page_exists_no_path (class: #{page_from_context.class.name})"
    end

    # Construct the base log message, escaping dynamic parts for safety.
    identifier_string = identifiers.map { |key, value| "#{key}='#{CGI.escapeHTML(value.to_s)}'" }.join(' ')
    safe_tag_type = CGI.escapeHTML(tag_type.to_s)
    safe_reason = CGI.escapeHTML(reason.to_s)
    log_message_base = "[#{message_level_symbol.to_s.upcase}] #{safe_tag_type}_FAILURE: Reason='#{safe_reason}' #{identifier_string} SourcePage='#{page_path}'".strip

    # --- 4. Console Logging ---
    # Log to console if message level meets or exceeds the site-wide plugin console log level.
    site_console_log_level_str = site.config['plugin_log_level']&.downcase || DEFAULT_SITE_CONSOLE_LEVEL_STRING
    site_console_log_level_val = LOG_LEVEL_MAP[site_console_log_level_str.to_sym] || LOG_LEVEL_MAP[DEFAULT_SITE_CONSOLE_LEVEL_STRING.to_sym]
    message_log_level_val = LOG_LEVEL_MAP[message_level_symbol]

    if message_log_level_val >= site_console_log_level_val
      # Attempt to use Jekyll.logger if available and responsive
      if defined?(Jekyll.logger) && Jekyll.logger.respond_to?(message_level_symbol)
        Jekyll.logger.public_send(message_level_symbol, "PluginLiquid:", log_message_base)
        # Fallback to puts if Jekyll.logger is not available or not responsive to the specific level
      else
        puts "[PLUGIN_LIQUID_LOG] #{log_message_base}"
      end
    end

    # --- 5. HTML Comment Logging ---
    # Generate an HTML comment if not in production environment.
    # This is independent of the site_console_log_level_val.
    html_output_comment = ""
    unless is_prod
      html_output_comment = "<!-- #{log_message_base} -->"
    end

    html_output_comment # Return the HTML comment (or empty string).
  end
end
