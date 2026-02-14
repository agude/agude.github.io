# frozen_string_literal: true

# _plugins/utils/plugin_logger_utils.rb
require 'cgi'
require 'jekyll'

module Jekyll
  module Infrastructure
    # Utility module for centralized logging with configurable log levels.
    module PluginLoggerUtils
      LOG_LEVEL_MAP = {
        debug: 0,
        info: 1,
        warn: 2,
        error: 3,
      }.freeze
      DEFAULT_MESSAGE_LEVEL_SYMBOL = :warn
      DEFAULT_SITE_CONSOLE_LEVEL_STRING = 'warn'

      # Centralized logging for Liquid tags/filters.
      # Handles console logging (respecting site.config['plugin_log_level'])
      # and HTML comment logging (for non-production environments).
      def self.log_liquid_failure(context:, tag_type:, reason:, identifiers: {}, level: DEFAULT_MESSAGE_LEVEL_SYMBOL)
        site = extract_site(context)

        return handle_missing_config(tag_type, level, reason) unless site_config_valid?(site)
        return '' unless logging_enabled?(site, tag_type)

        message = construct_log_message(context, tag_type, reason, identifiers, level)
        log_to_console(site, level, message)
        generate_html_comment(site, message)
      end

      class << self
        private

        def extract_site(context)
          return nil unless context.respond_to?(:registers) && context.registers.is_a?(Hash)

          context.registers[:site]
        end

        def site_config_valid?(site)
          site.respond_to?(:config) && site.config.is_a?(Hash)
        end

        def handle_missing_config(tag_type, level, reason)
          msg = '[PLUGIN LOGGER ERROR] Context, Site, or Site Config unavailable for logging. ' \
                "Original Call: #{tag_type} - #{level}: #{reason}"
          if defined?(Jekyll.logger) && Jekyll.logger.respond_to?(:error)
            Jekyll.logger.error('PluginLogger:', msg)
          else
            warn msg
          end
          ''
        end

        def logging_enabled?(site, tag_type)
          config = site.config['plugin_logging'] || {}
          config[tag_type.to_s] == true
        end

        def construct_log_message(context, tag_type, reason, identifiers, level)
          symbol = LOG_LEVEL_MAP.key?(level) ? level : DEFAULT_MESSAGE_LEVEL_SYMBOL
          path = extract_page_path(context)

          ids = identifiers.map { |k, v| "#{k}='#{CGI.escapeHTML(v.to_s)}'" }.join(' ')
          safe_tag = CGI.escapeHTML(tag_type.to_s)
          safe_reason = CGI.escapeHTML(reason.to_s)

          "[#{symbol.to_s.upcase}] #{safe_tag}_FAILURE: Reason='#{safe_reason}' #{ids} SourcePage='#{path}'".strip
        end

        def extract_page_path(context)
          page = context.registers[:page]
          if page.respond_to?(:[]) && page['path']
            page['path']
          elsif page
            "page_exists_no_path (class: #{page.class.name})"
          else
            'unknown_page'
          end
        end

        def log_to_console(site, level, message)
          site_val = _resolve_site_log_level(site)
          msg_symbol, msg_val = _resolve_message_log_level(level)

          return unless msg_val >= site_val

          _output_log_message(msg_symbol, message)
        end

        def _resolve_site_log_level(site)
          site_level = site.config['plugin_log_level']&.downcase || DEFAULT_SITE_CONSOLE_LEVEL_STRING
          LOG_LEVEL_MAP[site_level.to_sym] || LOG_LEVEL_MAP[DEFAULT_SITE_CONSOLE_LEVEL_STRING.to_sym]
        end

        def _resolve_message_log_level(level)
          msg_symbol = LOG_LEVEL_MAP.key?(level) ? level : DEFAULT_MESSAGE_LEVEL_SYMBOL
          msg_val = LOG_LEVEL_MAP[msg_symbol]
          [msg_symbol, msg_val]
        end

        def _output_log_message(msg_symbol, message)
          if defined?(Jekyll.logger) && Jekyll.logger.respond_to?(msg_symbol)
            Jekyll.logger.public_send(msg_symbol, 'PluginLiquid:', message)
          else
            puts "[PLUGIN_LIQUID_LOG] #{message}"
          end
        end

        def generate_html_comment(site, message)
          env = site.config['environment'] || 'development'
          is_prod = env.to_s.casecmp('production').zero?

          is_prod ? '' : "<!-- #{message} -->"
        end
      end
    end
  end
end
