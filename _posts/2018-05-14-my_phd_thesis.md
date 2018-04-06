---
layout: post
title: "My PhD Thesis, Explained"
description: >
  I graduated from the University of Minnesota in June, 2015. I wrote an
  esoteric thesis about Z boson decay, that I explain here.
image: /files/my-phd-thesis/
image_alt: >
use_latex: True
---

## Measurement of the phistar distribution of Z bosons decaying to electron pairs with the CMS experiment at a center-of-mass energy of 8 TeV

{% capture file_dir %}/files/my-phd-thesis/{% endcapture %}

<!--{% include lead_image.html %}-->

The [Standard Model][sm] of particle physics is one of the most accurate
theories humans have ever come up with, describing nature almost exactly as we
observe it. Yet we know it is incomplete, and even in the more complete areas
there are regions where it is very difficult to calculate what will happen.
One of these areas is low energy [quantum chromodynamics (QCD)][qcd], the part
of the theory that handles the interaction of [protons][p], [neutrons][n], and
the [quarks][q] that make them up, and the [gluons][g] that bind them
together.

[sm]: https://en.wikipedia.org/wiki/Standard_Model
[qcd]: https://en.wikipedia.org/wiki/Quantum_chromodynamics
[p]: https://en.wikipedia.org/wiki/Proton
[n]: https://en.wikipedia.org/wiki/Neutron
[q]: https://en.wikipedia.org/wiki/Quark
[g]: https://en.wikipedia.org/wiki/Gluon

For [my thesis][thesis], I studied the interaction $$pp \to Z \to e^-e^+$$:
two protons colliding to produce a [Z boson][z], which decays to two
[electrons][e] (well, an electron and a positron, but particle physicists just
call those electrons). This lets us explore the low energy QCD region (the
$$pp$$ collision) but using particles without any QCD interaction to make them
messy (the $$e^-e^+$$ pair). More specifically, I looked at the transverse
momentum, $$Q_T$$ of the Z boson, or how much the boson was moving in the
direction transverse to the proton beams at the time it decayed.

[thesis]: https://hdl.handle.net/11299/175445
[z]: https://en.wikipedia.org/wiki/W_and_Z_bosons
[e]: https://en.wikipedia.org/wiki/Electron

## The Large Hadron Collider and the Compact Muon Solenoid

The [Large Hadron Collider (LHC)][lhc] is a very large, and very high energy
particle collider on the boarder of Switzerland and France. It takes protons
and spins them around until they're traveling close to the speed of light, and
then smashes them together. This creates a lot of energy which is dissipated
by creating new particles. It allows us to test the Standard Model at a very
high energies where new particles may exist. Multiple smaller particle
accelerators feed into the LHC (as shown below), and it hosts four major
experiments: [ATLAS][atlas]; [ALICE][alice]; [LHCb][lhcb]; and [CMS][cms], the
Compact Muon Solenoid, which was my experiment.

[lhc]: https://en.wikipedia.org/wiki/Large_Hadron_Collider
[atlas]: https://en.wikipedia.org/wiki/ATLAS_experiment
[alice]: https://en.wikipedia.org/wiki/ALICE_experiment
[lhcb]: https://en.wikipedia.org/wiki/LHCb_experiment
[cms]: https://en.wikipedia.org/wiki/Compact_Muon_Solenoid

[![A diagram showing the LHC and the location of the four major experiments.
Also shown are the smaller accelerators the feed protons into the
LHC.][lhc_diagram]][lhc_diagram]

[lhc_diagram]: {{ file_dir }}/alex_lhc_layout.svg

CMS is a 14,000 ton physics experiment run by nearly 3000 physicists and
engineers. It is built around a proton-proton collision point and measures the
speed, mass, and direction of all the particles that are created after the two
protons collide. Some people like to think of it as a very large camera, and
that actually isn't so bad an analogy: like a camera, CMS measures particles
using silicon (and some other materials) and saves the output somewhere.

## Transverse Momentum

I said I studied low energy QCD, but then immediately introduced the highest
energy collider in the world. This is not, it turns out, a contradiction.
While the LHC is very high energy, all that energy is directed along the
beamline; the protons have almost no energy transverse to the beamline, and so
this gives us that low energy QCD system we desire. The $$Z \to ee$$ decay is
a great way to study this low energy regime because neither the Z nor the
electrons interact via QCD, and so the only QCD effects in the decay chain are
from the initial proton-proton collision.

I measured the transverse momentum, $$Q_T$$, of the Z boson, which is the way
the boson moves just before it decays. Measuring this not only tells us about
the low energy regime of QCD, but it also helps to constrain the mass of the W
boson, which is otherwise hard to measure, and is interesting because it helps
determine some fundamental quantities in the Standard Model and because there
is some disagreement between the measured value and the predicted value.

But actually, I didn't measure $$Q_T$$, I measured a new variable called
$$\phi^{*}$$, which measures the same effect as $$Q_T$$, but is more robust
against problems with the detector. $$\phi^{*}$$ measures the angle between
the two electrons instead of their energy, which is easier to measure
accurately due to the design of CMS.

## Backgrounds and Other Issues

The events I was interested in had two electrons in them, but not every event
with two electrons came from a Z decay. Events that produce two electrons for
other reasons are called _background_ events, and the primary difficulty in
any high energy experiment is separating the background from the events we are
interested in. The primary way we try to figure out what the background looks
like is through [Monte Carlo experiments (MC)][mc] where we generate virtual
data using the math prescribed by the Standard Model. We tune this generated
data on other particle decays that look similar to, but are not, the ones we
are interested in. For example, since I cared about double electron events, we
tuned our MC on events with one electron and one [muon][muon] (which is very
much like an electron, but heavier).

Below is an example of what the MC predicted the signal (blue) and backgrounds
(everything else) looked like for my experiment. The black points are all the
events selected for the analysis, so you can see the agreement is not perfect.

[mc]: https://en.wikipedia.org/wiki/Monte_Carlo_method
[muon]: https://en.wikipedia.org/wiki/Muon

[![A plot showing the Z mass peak in data, with stacked histograms showing the
estimated contribution from the background and signal events.][z_peak]][z_peak]

[z_peak]: {{ file_dir }}/z_peak.svg

There were other issues to work through as well, like estimating how good CMS
was at measuring various things. These biases were mostly corrected or
estimated by using MC events and putting them through the analysis pipeline.
This lets us check what the analysis would have measured, while having
information about the true underlying event.

## Results

[![A plot showing the final result comparing the measured phi star
distribution to the distributions predicted by various QCD Monte Carlo
simulations][result]][result]

[result]: {{ file_dir }}/final_result.svg

