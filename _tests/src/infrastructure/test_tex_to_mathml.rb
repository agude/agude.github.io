# frozen_string_literal: true

require 'test_helper'
require 'src/infrastructure/tex_to_mathml'

# Tests for TexToMathml: the site's TeX subset becomes MathML, and anything
# outside it stops the build.
class TestTexToMathml < Minitest::Test
  Tex = Jekyll::Infrastructure::TexToMathml

  def mathml(tex)
    Tex.convert(tex)
  end

  def body(tex)
    mathml(tex).delete_prefix('<math>').delete_suffix('</math>')
  end

  def test_inline_and_display_wrappers
    assert_equal '<math><mi>x</mi></math>', mathml('x')
    assert_equal '<math display="block"><mi>x</mi></math>', Tex.convert('x', display: true)
  end

  def test_identifiers_numbers_and_operators
    assert_equal '<mrow><mi>h</mi><mo stretchy="false">(</mo><mi>x</mi><mo stretchy="false">)</mo>' \
                 '<mo>=</mo><mn>2.5</mn><mi>x</mi><mo>−</mo><mn>1</mn></mrow>',
                 body('h(x) = 2.5x - 1')
  end

  def test_unicode_minus_and_spaces_are_tex_like
    assert_equal body('f(x)=h(x)-x'), body('f(x) = h(x) − x')
  end

  def test_scripts
    assert_equal '<msub><mi>Q</mi><mi>T</mi></msub>', body('Q_T')
    assert_equal '<msup><mi>ϕ</mi><mo lspace="0" rspace="0">∗</mo></msup>', body('\\phi^{*}')
    assert_equal body('\\phi^{*}'), body('\\phi^*')
    assert_equal '<mrow><msup><mi>e</mi><mo lspace="0" rspace="0">−</mo></msup>' \
                 '<msup><mi>e</mi><mo lspace="0" rspace="0">+</mo></msup></mrow>',
                 body('e^-e^+')
    assert_equal '<msubsup><mi>x</mi><mi>i</mi><mn>2</mn></msubsup>', body('x_i^2')
    # A lone operator script drops its infix spacing, as in TeX.
    assert_equal '<msub><mi>M</mi><mo lspace="0" rspace="0">±</mo></msub>', body('M_\\pm')
    assert_equal '<msup><mi>N</mi><mrow><mi>N</mi><mo>−</mo><mi>M</mi></mrow></msup>', body('N^{N-M}')
  end

  def test_symbols_functions_text_and_space
    assert_equal '<mrow><mi>log</mi><mo stretchy="false">(</mo><mi>λ</mi><mo stretchy="false">)</mo></mrow>',
                 body('\\log(\\lambda)')
    assert_equal '<mrow><mi>p</mi><mo>→</mo><mi>Z</mi><mo>±</mo></mrow>', body('p \\to Z \\pm')
    assert_equal '<msub><mi>P</mi><mtext>car-bike</mtext></msub>', body('P_{\\textrm{car-bike}}')
    assert_equal '<mrow><mi>a</mi><mspace width="0.1667em"></mspace><mi>b</mi></mrow>', body('a \\, b')
  end

  def test_escaped_braces_are_fixed_operators
    assert_equal '<mrow><mo stretchy="false">{</mo><mn>0</mn><mo>,</mo><mi>X</mi><mo stretchy="false">}</mo></mrow>',
                 body('\\{0, X\\}')
  end

  def test_frac_sqrt_binom
    assert_equal '<mfrac><mi>z</mi><mrow><mn>2</mn><mi>N</mi></mrow></mfrac>', body('\\frac{z}{2N}')
    assert_equal '<msqrt><mi>x</mi></msqrt>', body('\\sqrt{x}')
    assert_equal '<mrow><mo>(</mo><mfrac linethickness="0"><mi>N</mi><mi>M</mi></mfrac><mo>)</mo></mrow>',
                 body('\\binom{N}{M}')
  end

  def test_left_right_fences_stretch
    assert_equal '<mrow><mo fence="true" stretchy="true">[</mo><mi>P</mi><mo fence="true" stretchy="true">]</mo></mrow>',
                 body('\\left[ P \\right]')
    assert_equal '<mrow><mi>P</mi><mo fence="true" stretchy="true">)</mo></mrow>', body('\\left. P \\right)')
  end

  def test_every_expression_on_the_site_converts
    expressions = Dir.glob(File.expand_path('../../../_posts/*.md', __dir__)).flat_map do |path|
      File.read(path).scan(/\$\$(.+?)\$\$/m).flatten
    end
    assert_operator expressions.size, :>=, 40
    expressions.each { |tex| assert_match(%r{\A<math>.*</math>\z}m, mathml(tex.strip)) }
  end

  def test_unsupported_tex_raises
    ['\\int x', '\\begin{align}x\\end{align}', 'x & y', '{x', '\\left( x', 'x_', 'x__y', '\\left< x \\right>', '\\'].each do |tex|
      assert_raises(Tex::Error, tex) { mathml(tex) }
    end
  end

  def test_engine_stops_the_build_with_the_expression
    element = Kramdown::Element.new(:math, '\\int x', nil, category: :span, location: 12)
    error = assert_raises(Jekyll::Errors::FatalException) { Tex::KramdownEngine.call(nil, element, {}) }
    assert_includes error.message, '$$\\int x$$ on line 12'
    assert_includes error.message, "unsupported command '\\int'"
  end

  def test_kramdown_renders_math_through_the_engine
    html = Kramdown::Document.new("Inline $$x^2$$.\n\n$$\n\\sqrt{y}\n$$\n", math_engine: :mathjax).to_html
    assert_includes html, '<p>Inline <math><msup><mi>x</mi><mn>2</mn></msup></math>.</p>'
    assert_includes html, '<div class="math-display"><math display="block"><msqrt><mi>y</mi></msqrt></math></div>'
  end
end
