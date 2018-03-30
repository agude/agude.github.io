---
layout: post
title: "Matplotlib Animation Blitting: Supernova"
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

But making animations in [`matplotlib`][matplotlib] can take a long time. Not
just to write the code, but waiting for it to run! The easiest, but slowest,
way to make an animation is to redraw the entire plot every frame. Using this
method it took roughly 20 minutes to render a single animation for my [names
post][names]! Fortunately, there is a much faster way: matplotlib's
[ablitting][blit]. Blitting took that 20 minute render time to under a minute!

[matplotlib]: https://matplotlib.org
[blit]: https://en.wikipedia.org/wiki/Bit_blit

## The Data

We'll be using data from the [Nearby Supernova Factory][nsf],[^1] specifically
for [Supernova 2011fe][sn2011fe] from [Pereira et al.][pereira][^2] The
[spectrum][spectrum] of a supernova tells use a lot about how the star
exploded, and a time series of these spectra shows how the explosion changes
over time. The animation we'll be making in this post is shown below:

[nsf]: https://snfactory.lbl.gov
[sn2011fe]: https://en.wikipedia.org/wiki/SN_2011fe
[pereira]: https://doi.org/10.1051/0004-6361/201221008
[spectrum]: https://en.wikipedia.org/wiki/Astronomical_spectroscopy

{% capture video_file %}{{ file_dir }}/sn2011fe_spectral_time_series.mp4{% endcapture %}
{% include video.html file=video_file %}

The data is available [here][data]. The notebook with the code below is
[here][notebook] ([rendered on Github][rendered]).

{% capture notebook_uri %}{{ "Matplotlib Animation Blitting Example - Supernova Spectra.ipynb" | uri_escape }}{% endcapture %}

[data]: https://snfactory.lbl.gov/snf/data/SNfactory_Pereira_etal_2013_SN2011fe.tar.gz
[notebook]: {{ file_dir }}/{{ notebook_uri }}
[rendered]: https://github.com/agude/agude.github.io/blob/master{{ file_dir }}/{{ notebook_uri }}

## Blitting

Matplotlib uses blitting to produce animations by updating only the changing
foreground objects over a stationary background image. This is much faster
than re-rendering the entire plot. In order to use blitting, matplotlib
requires you to define three functions:

- [`init_func()`][init_func]: draws the static background.
- [`frames()`][frames]: yields the information needed to draw each update
- [`func(frame)`][func]: takes frame data and updates the artists

[init_func]: #init_func-function
[frames]: #frames-function
[func]: #func-function

### init_func Function

The `init_func()` draws the background of the animation. It takes no arguments
and must return an interable of [artists][artists]. The artists are the
objects that will be updated by [`func(frame)`][func].

[artists]: https://matplotlib.org/users/artists.html

{% highlight python %}
def init_fig(fig, ax, artists):
    """Initialize the figure, used to draw the first
    frame for the animation.

    Because this function must return a list of artists
    to be modified in the animation, a list is passed
    in and returned without being used or altered.

    Args:
      fig (matplotlib figure): a matplotlib figure object
      ax (matplotlib axis): a matplotlib axis object
      artists: a list of artist objects

    Returns:
      list: the unaltered input artists

    """
    # Set the axis and plot titles
    ax.set_title("Supernova 2011fe Spectrum", fontsize=22)
    ax.set_xlabel("Wavelength [Å]", fontsize=20)
    FLUX_LABEL = "Flux [erg s$​^{-1}$ cm$​^{-2}$ Å$​^{-1}$]"
    ax.set_ylabel(FLUX_LABEL, fontsize=20)

    # Set the axis range
    plt.xlim(3000, 10000)
    plt.ylim(0, 1.25e-12)

    # Set tick label size
    ax.tick_params(axis='both', which='major', labelsize=12)

    # Pad the ticks so they do not overlap at the corner
    ax.tick_params(axis='x', pad=10)
    ax.tick_params(axis='y', pad=10)

    # Must return the list of artists, but we use a pass
    # through so that they aren't created multiple times
    return artists
{% endhighlight %}

This function sets up the axises labels, sets the range of the plot, and would
do any other setup work needed like making a legend.

You will notice that I said it takes no arguments, but I gave it three anyway.
It's hard to have no inputs (without using globals), but one trick it to use
[partial application][partial], which I will demonstrate when we [put it all
together][put]. The function must return the list of artists to update, but I
find it's easier to declare those outside of the function and then pass them
in as an argument.

[partial]: https://en.wikipedia.org/wiki/Partial_application
[put]: #putting it together

### Frames Function

{% highlight python %}
def step_through_frames(from_day, until_day):
    """Iterate through the days of the spectra and return
    flux and day number.

    Args:
        from_day (int): start day, measured from B-max
        until_day (int): day to stop just before, measured
            from B-max

    Returns:
        tuple: a tuple containing the numpy array of flux
            values and the current day of the year

    """
    # B band max happened on a specific day, and we calculate
    # all dates from then
    B_MAX_STR = "2011-09-10T12:40:10"
    FORMAT_STR = "%Y-%m-%dT%H:%M:%S"
    b_max_date = datetime.strptime(B_MAX_STR, FORMAT_STR)
    for ten_day in range(from_day * 10, until_day * 10):
        day = ten_day / 10
        flux = flux_from_day(day)

        date = b_max_date + timedelta(day)

        yield (flux_from_day(day), date.strftime("%Y-%m-%d"))
{% endhighlight %}

### Func Function

{% highlight python %}
def update_artists(frames, artists, lambdas):
    """Update artists with data from each frame.

    Args:
        frames (tuple): contains the flux values as a numpy
            array and days from B-Max as a float
        artists (list of Artists): a list of artists to update

    """
    flux, day = frames

    artists.flux_line.set_data(lambdas, flux)
    artists.day.set_text(day)
{% endhighlight %}

### Putting it together

Once we've written the three functions.

{% highlight python %}
# Create the plot
fig, ax = plt.subplots(figsize=(12, 7))

# Set the artists
artists = Artists(
    plt.plot([], [], animated=True, label="Flux")[0],
    ax.text(0.987, 0.955, "", fontsize=20, transform=ax.transAxes, horizontalalignment='right', verticalalignment='center'),
)

# Apply the three plotting functions written above
init = partial(init_fig, fig=fig, ax=ax, artists=artists)
step = partial(step_through_frames, -15, 25)
update = partial(update_artists, artists=artists, lambdas=df["lambda"].unique())

# Generate the animation
anim = animation.FuncAnimation(
    fig=fig,
    func=update,
    frames=step,
    init_func=init,
    save_count=len(list(step())),
    repeat_delay=5000,
)

# Save the animation
anim.save('/tmp/sn2011fe_spectral_time_series.mp4', fps=24, extra_args=['-vcodec', 'libx264'], dpi=300, metadata=VIDEO_META)
{% endhighlight %}

## A little extra

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

[^1]: Aldering et al., *Overview of the Nearby Supernova Factory*, Proceedings Volume 4836, Survey and Other Telescope Technologies and Discoveries; (2002); doi: [10.1117/12.458107][aldering_2002]
[^2]: Pereira et al., *Spectrophotometric time series of SN 2011fe from the Nearby Supernova Factory*, A&A 554, A27 (2013), doi: [10.1051/0004-6361/201221008][pereira]

[aldering_2002]: https://doi.org/10.1117/12.458107
