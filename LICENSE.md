# Released under MIT License

Copyright (c) 2013 Mark Otto.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

# Fonts

The fonts in `assets/fonts/` are not covered by the MIT License above. Each
keeps its own license, and each file carries its copyright and license notice
in its name table.

- `ubuntu-mono-v19-latin-*.woff2`: Ubuntu Mono, copyright 2011 Canonical Ltd.,
  under the [Ubuntu Font Licence 1.0](https://ubuntu.com/legal/font-licence).
- `gude-math-latin-modern-subset.woff2`: "Gude Math", a modified version of
  [Latin Modern Math](https://ctan.org/pkg/lm-math) 1.959, copyright 2012–2014
  B. Jackowski, P. Strzelczyk, and P. Pianowski, under the
  [GUST Font License](https://tug.org/fonts/licenses/GUST-FONT-LICENSE.txt), an
  instance of the LaTeX Project Public License 1.3c. It is reduced to the
  characters the site's math uses, has its OpenType layout features removed, and
  is renamed. `_scripts/fonts/subset_math_font.py` builds it from the
  unmodified font, which is available at the link above. The authors of Latin
  Modern Math do not support this version.
