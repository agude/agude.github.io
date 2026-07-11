# frozen_string_literal: true

require 'jekyll'
require 'liquid'
require_relative '../author_link_resolver'
require_relative '../../../infrastructure/links/link_tag_base'

module Jekyll
  module Authors
    module Tags
      # Liquid tag for creating links to author pages.
      # Supports optional display text override, link toggle, and possessive
      # suffix. Arguments can be in flexible order after the name.
      #
      # Usage: {% author_link "Name" [link_text="Display Text"] [link=false] [possessive] %}
      #        {% author_link variable [link_text=var2] [possessive] %}
      class AuthorLinkTag < Jekyll::Infrastructure::Links::LinkTagBase
        self.subject = 'author name'
        self.resolver_class = Jekyll::Authors::AuthorLinkResolver
        self.option_spec = { link_text: :value, link: :value, possessive: :flag }

        private

        def resolver_arguments(context)
          positional = [
            subject_value(context),
            option_value(:link_text, context),
            flag?(:possessive),
          ]
          [positional, { link: option_enabled?(:link, context) }]
        end

        def markdown_result(data, context)
          no_link = !option_enabled?(:link, context) || LinkHelper.self_link?(context, data[:url])
          result = MdLink.format_link(data, self_link: no_link)
          data[:possessive] ? "#{result}'s" : result
        end
      end
    end
  end
end

# Register the tag with Liquid so Jekyll recognizes {% author_link ... %}
Liquid::Template.register_tag('author_link', Jekyll::Authors::Tags::AuthorLinkTag)
