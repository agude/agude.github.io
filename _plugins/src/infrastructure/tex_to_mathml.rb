# frozen_string_literal: true

require 'cgi'
require 'jekyll'
require 'kramdown'

module Jekyll
  module Infrastructure
    # Converts the small subset of TeX math the site uses into MathML at
    # build time, so pages render math with no JavaScript, no CDN, and no
    # gem. Browsers render MathML Core natively (Baseline 2023).
    #
    # Registered as kramdown's math engine (see the bottom of this file and
    # `kramdown.math_engine` in `_config.yml`): kramdown hands it each
    # `$$...$$` span or block, and its return value replaces the math in
    # the HTML.
    #
    # Supported TeX, which is everything the posts use:
    # - letters (one `<mi>` each), numbers, `+ - = ( ) [ ] , / | * ' !`,
    #   the Unicode minus, spaces (ignored, as in TeX);
    # - `_` and `^` with one token or a `{...}` group;
    # - `\{ \}`, `\,`, `\textrm{...}`, `\frac`, `\sqrt`, `\binom`,
    #   `\left` / `\right`, and the names in SYMBOLS and FUNCTIONS.
    #
    # @validator Any other command or character stops the build, naming the
    #   expression and the page. Add the command here; do not reach for a
    #   math library.
    module TexToMathml
      # Command name => [MathML element, content].
      SYMBOLS = {
        'alpha' => %w[mi α],
        'beta' => %w[mi β],
        'gamma' => %w[mi γ],
        'delta' => %w[mi δ],
        'epsilon' => %w[mi ϵ],
        'lambda' => %w[mi λ],
        'mu' => %w[mi μ],
        'pi' => %w[mi π],
        'sigma' => %w[mi σ],
        'phi' => %w[mi ϕ],
        'Phi' => %w[mi Φ],
        'pm' => %w[mo ±],
        'mp' => %w[mo ∓],
        'to' => %w[mo →],
        'times' => %w[mo ×],
        'cdot' => %w[mo ⋅],
        'leq' => %w[mo ≤],
        'geq' => %w[mo ≥],
        'neq' => %w[mo ≠],
        'approx' => %w[mo ≈],
        'infty' => %w[mi ∞],
        '{' => %w[mo {],
        '}' => %w[mo }],
      }.freeze
      # Upright function names, set as one identifier.
      FUNCTIONS = %w[log ln exp sin cos tan min max].freeze
      # TeX's "\," thin space.
      THIN_SPACE = '<mspace width="0.1667em"></mspace>'
      OPERATORS = {
        '+' => '+',
        '-' => '−',
        '−' => '−',
        '=' => '=',
        '(' => '(',
        ')' => ')',
        '[' => '[',
        ']' => ']',
        ',' => ',',
        '/' => '/',
        '|' => '|',
        '*' => '∗',
        "'" => '′',
        '!' => '!',
        '<' => '<',
        '>' => '>',
      }.freeze
      DELIMITERS = { '(' => '(', ')' => ')', '[' => '[', ']' => ']', '|' => '|', '.' => '' }.freeze
      FIXED_FENCES = %w[( ) [ ] { } | /].freeze
      private_constant :SYMBOLS, :FUNCTIONS, :THIN_SPACE, :OPERATORS, :DELIMITERS, :FIXED_FENCES

      # Raised for TeX outside the supported subset.
      class Error < StandardError; end

      # @param tex [String] The math, without `$$` delimiters.
      # @param display [Boolean] True for a display (block) equation.
      # @return [String] One `<math>` element.
      # @raise [Error] For unsupported TeX.
      def self.convert(tex, display: false)
        body = Parser.new(tex).parse
        display ? %(<math display="block">#{body}</math>) : "<math>#{body}</math>"
      end

      # Recursive-descent parser over the TeX string; each method returns
      # MathML text.
      class Parser
        def initialize(tex)
          @tex = tex
          @pos = 0
        end

        def parse
          row = sequence(stop: nil)
          raise Error, "unexpected '#{@tex[@pos]}'" if @pos < @tex.length

          row
        end

        private

        # Terms up to `stop` ('}' or :right), returned as one row.
        def sequence(stop:)
          items = []
          loop do
            skip_spaces
            break if @pos >= @tex.length || at_stop?(stop)

            items << scripted(atom)
          end
          items.size == 1 ? items.first : "<mrow>#{items.join}</mrow>"
        end

        def at_stop?(stop)
          (stop == '}' && peek == '}') || (stop == :right && @tex[@pos..].start_with?('\\right'))
        end

        # An atom followed by any `_` and `^` scripts.
        def scripted(base)
          sub = sup = nil
          loop do
            skip_spaces
            case peek
            when '_' then sub = script_argument('_', sub)
            when '^' then sup = script_argument('^', sup)
            else break
            end
          end
          return base unless sub || sup
          return "<msubsup>#{base}#{sub}#{sup}</msubsup>" if sub && sup

          sub ? "<msub>#{base}#{sub}</msub>" : "<msup>#{base}#{sup}</msup>"
        end

        def script_argument(mark, existing)
          raise Error, "double '#{mark}'" if existing

          @pos += 1
          skip_spaces
          lone_operator_unspaced(atom)
        end

        # A lone operator script (`M_\pm`) keeps its infix spacing in
        # MathML, which leaves a gap after the subscript; TeX sets none.
        def lone_operator_unspaced(script)
          script.sub(/\A<mo(?=[ >])/, '<mo lspace="0" rspace="0"')
        end

        def atom
          char = peek
          raise Error, 'missing argument' if char.nil?

          @pos += 1
          case char
          when '{' then group_rest
          when '\\' then command
          when /[A-Za-z]/ then "<mi>#{char}</mi>"
          when /[0-9.]/ then number(char)
          else
            raise Error, "unsupported character '#{char}'" unless OPERATORS.key?(char)

            operator(OPERATORS[char])
          end
        end

        # TeX stretches only \left and \right delimiters; MathML stretches
        # fence characters by default, so a plain one is marked fixed.
        def operator(symbol)
          fixed = FIXED_FENCES.include?(symbol) ? ' stretchy="false"' : ''
          "<mo#{fixed}>#{escape(symbol)}</mo>"
        end

        # After an opening '{': the group's contents and its closing '}'.
        def group_rest
          row = sequence(stop: '}')
          raise Error, "unclosed '{'" unless peek == '}'

          @pos += 1
          row
        end

        def number(first)
          digits = first + @tex[@pos..][/\A[0-9.]*/]
          @pos += digits.length - 1
          "<mn>#{digits}</mn>"
        end

        def command
          name = @tex[@pos..][/\A(?:[A-Za-z]+|.)/]
          raise Error, "lone '\\'" if name.nil?

          @pos += name.length
          return THIN_SPACE if name == ','
          return "<mi>#{name}</mi>" if FUNCTIONS.include?(name)

          if SYMBOLS.key?(name)
            element, content = SYMBOLS[name]
            return element == 'mo' ? operator(content) : "<#{element}>#{escape(content)}</#{element}>"
          end

          structure(name)
        end

        def structure(name)
          case name
          when 'frac' then "<mfrac>#{argument}#{argument}</mfrac>"
          when 'sqrt' then "<msqrt>#{argument}</msqrt>"
          when 'binom'
            %(<mrow><mo>(</mo><mfrac linethickness="0">#{argument}#{argument}</mfrac><mo>)</mo></mrow>)
          when 'textrm' then "<mtext>#{escape(text_argument)}</mtext>"
          when 'left' then fenced
          else raise Error, "unsupported command '\\#{name}'"
          end
        end

        # A required `{...}` argument (or a single token).
        def argument
          skip_spaces
          atom
        end

        def text_argument
          skip_spaces
          raise Error, '\\textrm needs {text}' unless peek == '{'

          close = @tex.index('}', @pos)
          raise Error, "unclosed '{'" unless close

          text = @tex[(@pos + 1)...close]
          @pos = close + 1
          text
        end

        # After `\left`: delimiter, contents, `\right`, delimiter.
        def fenced
          open = delimiter
          inner = sequence(stop: :right)
          raise Error, '\\left without \\right' unless @tex[@pos..].start_with?('\\right')

          @pos += '\\right'.length
          close = delimiter
          "<mrow>#{fence_mo(open)}#{inner}#{fence_mo(close)}</mrow>"
        end

        def delimiter
          skip_spaces
          token = @tex[@pos..].start_with?('\\{', '\\}') ? @tex[@pos, 2] : peek
          symbol = { '\\{' => '{', '\\}' => '}' }.fetch(token) { DELIMITERS[token] }
          raise Error, "unsupported delimiter '#{token}'" if symbol.nil?

          @pos += token.length
          symbol
        end

        def fence_mo(symbol)
          symbol.empty? ? '' : %(<mo fence="true" stretchy="true">#{escape(symbol)}</mo>)
        end

        def peek
          @tex[@pos]
        end

        def skip_spaces
          @pos += 1 while peek&.match?(/\s/)
        end

        def escape(text)
          CGI.escapeHTML(text)
        end
      end
      private_constant :Parser

      # kramdown math engine: `call(converter, element, options)`.
      module KramdownEngine
        def self.call(_converter, element, _options)
          display = element.options[:category] == :block
          mathml = TexToMathml.convert(element.value, display: display)
          # Firefox and WebKit do not scroll a <math> element, so a display
          # equation sits in a div that scrolls when it is wider than the
          # column (`.math-display` in _sass/_base.scss).
          display ? %(<div class="math-display">#{mathml}</div>\n) : mathml
        rescue Error => e
          location = element.options[:location] ? " on line #{element.options[:location]}" : ''
          raise Jekyll::Errors::FatalException,
                "TexToMathml: #{e.message} in $$#{element.value}$$#{location}. " \
                'Add the TeX to TexToMathml (_plugins/src/infrastructure/tex_to_mathml.rb).'
        end
      end
    end
  end
end

# Registered as `mathjax`, replacing kramdown's built-in engine of that name
# (which emits \( \) for the MathJax script). Jekyll requires a
# `kramdown-math-<name>` gem for any other engine name.
Kramdown::Converter.add_math_engine(:mathjax, Jekyll::Infrastructure::TexToMathml::KramdownEngine)
