---
layout: post
title: "Improving Old Supernova Plotting Code"
description: >
  I learned to use matplotlib more than ten years ago. Around that time, I
  made a plot of supernova 2002cx for Wikipedia, but it was not terrible good.
  So this year, I updated it!
image: /files/supernova-plot-update/virgo_by_sidney_hall.jpg
image_alt: >
  A drawing by Sidney Hall of the constellation Virgo represented as a Woman
  with angel wings and a pink and green dress.
---

{% capture file_dir %}/files/supernova-plot-update/{% endcapture %}

{% capture old_notebook_uri %}{{ "Old Plot.ipynb" | uri_escape }}{% endcapture %}
[old_plot_code]: {{ file_dir }}/{{ old_notebook_uri }}
[old_rendered]: https://github.com/agude/agude.github.io/blob/master{{ file_dir }}/{{ old_notebook_uri }}

{% capture new_notebook_uri %}{{ "New Plot.ipynb" | uri_escape }}{% endcapture %}
[new_plot_code]: {{ file_dir }}/{{ new_notebook_uri }}
[new_rendered]: https://github.com/agude/agude.github.io/blob/master{{ file_dir }}/{{ new_notebook_uri }}

## Area Normalization

I do some light data processing before plotting. One of these is normalizing
the area of the spectra. The spectra is two arrays: a set of wavelengths and
the associated amount of flux at that wavelength. I originally wrote this
function:

{% highlight python %}
# Function to normalize to area
def areaNorm(X, Y):
    dX = abs(X[0] - X[1])
    area = sum(Y) * dX
    Y = (Y / area) * 1000
    return (X, Y)
{% endhighlight python %}

It is succinct, but to the point of being tough to read. The variable names
are not horrible, they follow mathematical convention at least, but they make
the reader convert between "wavelength" and `X` in their head. There is also
the inscrutable [magic number][magic_number] `1000` that is completely
unexplained.

[magic_number]: https://en.wikipedia.org/wiki/Magic_number_(programming)

My improved version is many lines longer, but is much more readable:

{% highlight python %}
def normalize_area(wavelengths, fluxes):
    """Takes a binned spectrum as two arrays and returns the flux normalized to
    an area of 1000.

    Args:
        wavelengths (array): The wavelengths of the center of each bin of the
            spectrum.
        fluxes (array): The flux value for each bin.

    Returns:
        array: The flux values normalized to have a total area of 1000.

    """
    desired_area = 1000
    bin_width = wavelengths[1] - wavelengths[0]
    area = sum(fluxes) * bin_width
    normed_fluxes = (fluxes / area) * desired_area

    return normed_fluxes
{% endhighlight python %}

The function now has a doc string to help the reader (and even future callers)
understand what it is doing. The variables and function names are now
properly [snake_case][snake_case] as recommended for Python, and have
descriptive names so the reader no longer has to remember to map "flux" to
`Y`. Finally, I assigned the [magic number][magic_number] to a named constant
to make it clear what it is.

[snake_case]: https://en.wikipedia.org/wiki/Snake_case

## Data Loading


