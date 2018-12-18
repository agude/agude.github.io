---
layout: post
title: "Making Animations Quickly with Matplotlib Blitting"
description: >
  Animating plots is great way to show how some quantity changes in time, but
  they can be slow to generate in matplotlib! Thankfully, blitting makes
  animating much faster! Learn how to here!
image: /files/matplotlib-blitting-supernova/m101.jpg
image_alt: >
  A color image of the M101 Pinwheel Galaxy, a spiral galaxy, composed of
  multiple exposures taken by NASA and the European Space Agency.
---

{% capture file_dir %}/files/matplotlib-blitting-supernova{% endcapture %}

{% include lead_image.html %}

Animations are a great way to show the passage of time in a plot. I have used
animation to show [how long my Raspberry Pis take to reboot][reboot] and [how
the popularity of names changed in the US][names].

[reboot]: {% post_url 2017-11-13-raspberry_pi_reboot_times %}
[names]: {% post_url 2018-02-28-popular_names %}

But making animations in [matplotlib][matplotlib] can take a long time. Not
just to write the code, but waiting for it to run! The easiest, but slowest,
way to make an animation is to redraw the entire plot every frame. Using this
method, it took roughly 20 minutes to render a single animation for my [names
post][names]! Fortunately there is a significantly faster alternative:
matplotlib's [animation blitting][blit]. Blitting increased rendering speed by
a factor of 20!

[matplotlib]: https://matplotlib.org
[blit]: https://en.wikipedia.org/wiki/Bit_blit

## The Data

We will plot the spectrum of [Supernova 2011fe][sn2011fe] from [Pereira et
al.][pereira][^1] by the [Nearby Supernova Factory][nsf].[^2] The
[spectrum][spectrum] of a supernova tells us about what is going on in the
explosion, so looking at a time series tells us how the explosion is evolving.

[nsf]: https://snfactory.lbl.gov
[sn2011fe]: https://en.wikipedia.org/wiki/SN_2011fe
[pereira]: https://doi.org/10.1051/0004-6361/201221008
[spectrum]: https://en.wikipedia.org/wiki/Astronomical_spectroscopy

The data is available [here][data]. The notebook with all the code is
[here][notebook] ([rendered on Github][rendered]). The code in the notebooks
is complete, including doc strings and comments, while I have stripped down
the examples below for clarity.

{% capture notebook_uri %}{{ "Matplotlib Animation Blitting Example - Supernova Spectra.ipynb" | uri_escape }}{% endcapture %}

[data]: https://snfactory.lbl.gov/snf/data/SNfactory_Pereira_etal_2013_SN2011fe.tar.gz
[notebook]: {{ file_dir }}/{{ notebook_uri }}
[rendered]: https://github.com/agude/agude.github.io/blob/master{{ file_dir }}/{{ notebook_uri }}

This is the animation we will be making:

{% capture video_file %}{{ file_dir }}/sn2011fe_spectral_time_series.mp4{% endcapture %}
{% include video.html file=video_file %}

It shows the amount of light (flux) the telescope saw as a function of the
wavelength of light. The data was only sampled once every few days, so to make
the animation smooth we will linearly interpolate the data. This is
implemented by the function `flux_from_day(day)`, which returns a numpy array
of flux values for a specific day. The details of how the function works can
be found in the [notebook][notebook].

## Blitting

Blitting breaks the animation into two components: the unchanging background
elements, and the [artist objects][artists] that are updated each frame. It
requires us to write three functions:

[artists]: https://matplotlib.org/users/artists.html

- [`init_fig()`][init_fig]: draws the static background
- [`frame_iter()`][frame_iter]: yields the `frame_data` needed to draw each update
- [`update_artists(frame_data)`][update_artists]: takes `frame_data` and
updates the artists

[init_fig]: #init_fig-function
[frame_iter]: #frame_iter-function
[update_artists]: #update_artists-function

The artists that are updated each frame must be kept in an iterable container.
A normal list will work, but a more convenient way to do this is using a
[`namedtuple`][namedtuple] (which I [discuss in detail in another
post][tuple_post]). This will let us access the different artists by name, for
example `artists.flux_line`, instead of having to remember their index number.

[namedtuple]: https://docs.python.org/2/library/collections.html#collections.namedtuple
[tuple_post]: {% post_url 2018-12-18-python_patterns_namedtuple %}

### init_fig Function

The `init_fig()` function draws the background of the animation. It takes no
arguments and must return an iterable of the artists to be updated every
frame, which in our case are contained in the namedtuple discussed above.

Our example function sets the labels, the title, and the range of the plot. It
is here where we would draw anything else that is unchanging, like the legend,
or some text labels, if we needed to. Here it is:

{% highlight python %}
def init_fig(fig, ax, artists):
    """Initialize the figure, used to draw the first
    frame for the animation.
    """
    # Set the axis and plot titles
    ax.set_title("Supernova 2011fe Spectrum", fontsize=22)
    ax.set_xlabel("Wavelength [Å]", fontsize=20)
    FLUX_LABEL = "Flux [erg s$^{-1}$ cm$^{-2}$ Å$^{-1}$]"
    ax.set_ylabel(FLUX_LABEL, fontsize=20)

    # Set the axis range
    plt.xlim(3000, 10000)
    plt.ylim(0, 1.25e-12)

    # Must return the list of artists, but we use a pass
    # through so that they aren't created multiple times
    return artists
{% endhighlight %}

You will notice that I said the function takes no arguments, but I gave it
three anyway. It's hard to have no inputs (without using globals), but one
trick is to use [partial application][partial], which I will demonstrate when
we [put it all together][put]. The function must return the list of artists to
update, but I find it's easier to declare those outside of the function and
then pass them in as an argument.

[partial]: https://en.wikipedia.org/wiki/Partial_application
[put]: #putting-it-all-together

### frame_iter Function

The `frame_iter()` function is a generator that returns the data needed to
update the artist for each frame. It yields `frame_data`, which can be any
sort of Python data type or object. This function also must take no arguments,
and so like [`init_fig()`][init_fig] we will use the partial application trick
to bind the arguments.

Our function loops over the days relative to maximum light and returns the
flux values from that day, as well as string of the day to update the text
label.

{% highlight python %}
def frame_iter(from_day, until_day):
    """Iterate through the days of the spectra and return
    flux and day number.
    """
    for day in range(from_day, until_day):
        flux = flux_from_day(day)
        # Yield events so the function can be looped over
        yield (flux, "Day: {day}".format(day))
{% endhighlight %}

### update_artists Function

Once we have [`frame_iter()`][frame_iter] to generate the data for each frame,
`update_artists()` is really simple. All it has to do is:

1. Unpack the `frames_data`.
2. Update the plot line and the text.

For the plot line we call `.set_data()` to insert the new values; for the text
we call `.set_text()`. Our function is short:

{% highlight python %}
def update_artists(frames, artists, lambdas):
    """Update artists with data from each frame."""
    flux, day = frames

    artists.flux_line.set_data(lambdas, flux)
    artists.day.set_text(day)
{% endhighlight %}

Lines and text are easy to update, but other plot objects (like histograms)
are associated with multiple artists, which makes it harder to update them.
Unfortunately, the only solution is to write a much more complicated update
function for each type.

### Putting it all together

Once we've written the three functions, it is pretty simple to make our
animation:

1. Create the figure (`fig`) and axes (`ax`).
2. Create the list of artists, in this case a line (`plt.plot`) and some text
   (`ax.text`).
3. Partially apply the functions by binding inputs to them with `partial`.
4. Create the animation object (`animation.FuncAnimation`).
5. Save the animation as an `.mp4` (`anim.save`).

Here are those steps in code:

{% highlight python %}
# 1. Create the plot
fig, ax = plt.subplots(figsize=(12, 7))

# 2. Initialize the artists with empty data
Artists = namedtuple("Artists", ("flux_line", "day"))
artists = Artists(
    plt.plot([], [], animated=True)[0],
    ax.text(x=0.987, y=0.955, s=""),
)

# 3. Apply the three plotting functions written above
init = partial(init_fig, fig=fig, ax=ax, artists=artists)
step = partial(frame_iter, from_day=-15, until_day=25)
update = partial(update_artists, artists=artists,
                 lambdas=np.arange(3298, 9700, 2.5))

# 4. Generate the animation
anim = animation.FuncAnimation(
    fig=fig,
    func=update,
    frames=step,
    init_func=init,
    save_count=len(list(step())),
    repeat_delay=5000,
)

# 5. Save the animation
anim.save(
  filename='/tmp/sn2011fe_spectral_time_series.mp4',
  fps=24,
  extra_args=['-vcodec', 'libx264'],
  dpi=300,
)
{% endhighlight %}

The only tricky thing is the use of partial applications. Partial application
binds some (or all) of the arguments to the function and creates a new
function that takes fewer arguments. Essentially, it's like setting a default
value for the arguments.

For the `update()` function above, we use partial application to fix some of
the arguments, while leaving the `frame` argument as one that still must be
supplied at call time. To create the `init()` and `step()` functions above, we
fully apply the parent functions, allowing the new functions to be called
without any inputs.

## A Little Extra

Of course, you can add a bit more to the plot, like the [photometrics
filters][filters] used:

[filters]: https://en.wikipedia.org/wiki/Photometric_system

{% capture video_file_extra %}{{ file_dir }}/sn2011fe_spectral_time_series_extra.mp4{% endcapture %}
{% include video.html file=video_file_extra %}

But that would have made the example even harder to follow. If you're
interested, the notebook to generate that plot is [here][notebook_extra]
([rendered on Github][rendered_extra]).

{% capture notebook_extra_uri %}{{ "Matplotlib Animation Blitting Example - Supernova Spectra Extra.ipynb" | uri_escape }}{% endcapture %}

[notebook_extra]: {{ file_dir }}/{{ notebook_extra_uri }}
[rendered_extra]: https://github.com/agude/agude.github.io/blob/master{{ file_dir }}/{{ notebook_extra_uri }}

---

[^1]: Pereira et al., *Spectrophotometric time series of SN 2011fe from the Nearby Supernova Factory*, A&A 554, A27 (2013), doi: [10.1051/0004-6361/201221008][pereira]
[^2]: Aldering et al., *Overview of the Nearby Supernova Factory*, Proceedings Volume 4836, Survey and Other Telescope Technologies and Discoveries; (2002); doi: [10.1117/12.458107][aldering_2002]

[aldering_2002]: https://doi.org/10.1117/12.458107
