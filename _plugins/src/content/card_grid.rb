# frozen_string_literal: true

module Jekyll
  module Content
    # Renders a grid of cards, with an optional headed aside.
    # @pattern Callers supply each card's markup, including any trailing newline.
    module CardGrid
      def self.render(documents, heading: nil, aside_class: 'related', render_empty: false)
        return '' if !render_empty && documents.empty?

        output = +''
        output << "<aside class=\"#{aside_class}\">\n  #{heading}\n  " if heading
        output << "<ul class=\"card-grid\">\n"
        documents.each { |document| output << yield(document) }
        output << (heading ? "  </ul>\n</aside>" : "</ul>\n")
      end
    end
  end
end
