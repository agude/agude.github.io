---
layout: post
title: "AI, Artists, and Technology"
description: >
  AI generated art took off with the open-source release of Stable Diffusion,
  leaving some artists worried. As an artist and machine learning engineer,
  here is my take.
image: /files/ai_artists_and_technology/field_of_yellow_by_alex_gude_oil_painted_by_stable_diffusion.jpg
hide_lead_image: False
image_alt: >
  An image generated from one of my landscape photos using Stable Diffusion
  with img2img to make it look more like an oil painting. It shows yellow
  flowers, with a forest behind them. The Jura Mountains loom behind the
  forest, and the sky is bright blue with some large white clouds.
categories: 
  - generative-ai
  - machine-learning
  - opinions
---

{% capture file_dir %}/files/ai_artists_and_technology{% endcapture %}

The open-source release of [Stable Diffusion][sd] has sparked an explosion of
progress in [AI-generated art][ai_art]. Although it is in its infancy, I can
already tell this new tool is going to revolutionize visual art creation. But
not everyone views AI art in a positive light. Many artists feel that [AI art
stole their work][stolen][^stolen_quote] and have [organized protests][anti]
on popular sites like _ArtStation_. Other artists [claim that AI-generated art
can't be art][not_art][^not_art_quote] because it isn't
human.

[sd]: https://en.wikipedia.org/wiki/Stable_Diffusion
[ai_art]: https://en.wikipedia.org/wiki/Artificial_intelligence_art
[stolen]: https://twitter.com/Artofinca/status/1599730391698485248
[anti]: https://arstechnica.com/information-technology/2022/12/artstation-artists-stage-mass-protest-against-ai-generated-artwork/
[not_art]: https://www.vice.com/en/article/ake9me/artists-are-revolt-against-ai-art-on-artstation

[^stolen_quote]:
    > Current AI "art" is created on the backs of hundreds of thousands of
    > artists and photographers who made billions of images and spend time,
    > love and dedication to have their work soullessly stolen and used by
    > selfish people for profit without the slightest concept of ethics.

    [Alexander Nanitchkov (@Artofinca)][stolen], Twitter, 2022-12-05

[^not_art_quote]:

    >"I believe art is something inherently and intrinsically human, even
    >corporate art made-for-hire is meticulously crafted by experts in their
    >fields," [Nicholas] Kole said. "When we sit down to draw, design, sculpt
    >or paint, each mark is made with an intention. Each step of the process
    >is an opportunity to ask new questions, tune the piece to the precise
    >context it's intended for, to add expressiveness and even a point of
    >view. The result—movies, shows, games—are intended to connect that
    >intricate craft with an audience who appreciates and enjoys it." 
    >
    >AI does none of this, he explained, and he sees "a world filling up with
    >meaningless, regurgitative cardboard cutouts that remind us of real art."

    [Xiang, Chloe][chloe]. [_Artists Are Revolting Against AI Art on
    ArtStation._][not_art] Vice, 2022-12-14

[chloe]: https://twitter.com/chloexiang

## AI and Photography as Art

I come down on the side of AI-artists.

This is probably unsurprising because I am a machine learning engineer, it is
my job to build the types of systems these artists are using. But what is less
obvious is that my support is also because I am an artist, specifically a
landscape photographer.

Photography---just like AI-generated art---has [a complicated history as
"art"][jstor]. Although the first photograph was taken in 1826, it wasn't
until 1924 that an American museum recognized the medium as art by [including
photographs in its permanent collection][as]. At first artists feared
photography would replace traditional visual arts due to the ease of taking a
picture. But eventually they realized it was a useful tool that could be
combined with other art forms, even if they did not recognize photography as
an art in its own right.[^brush_and_pencil]<sup>, </sup>[^the_new_path]

[jstor]: https://daily.jstor.org/when-photography-was-not-art/

[as]: https://en.wikipedia.org/wiki/Alfred_Stieglitz

[^brush_and_pencil]: 
    > The fear has sometimes been expressed that photography would in time
    > entirely supersede the art of painting. Some people seem to think that
    > when the process of taking photographs in colors has been perfected and
    > made common enough, the painter will have nothing more to do. We need
    > not fear anything of the kind. Perfection in photography may rid us in
    > time of all the poor work done in color. The work of the artist,
    > however, in which is seen his own individuality, his own perception of
    > the beautiful, his own creation in fact, can no more perish than the
    > soul which inspired it.  

    Henrietta Clopath. _Genuine Art versus Mechanism_, in [_Brush and Pencil_
    Vol. 7, No. 6 (1901-03-01)][bap], pp. 331-333

[bap]: https://doi.org/10.2307/25505621

[^the_new_path]:
    > Photography is an infinitely valuable mechanism by which to obtain records
    > of limited abstract truth, and as such, may be of great service to the
    > artist. Much may be learned about drawing by reference to a good photograph,
    > that even a man of quick natural perception would be slow to learn without
    > such help. But, unless the real shortcomings of the photograph are
    > understood, it must certainly mislead if followed.
    >
    > But beyond these merely technical matters, art differs from any
    > mechanical process in being "the expression of man's delight in God's
    > work", and thus it appeals to, and awakens all noble sympathy and right
    > feeling. All labor of love must have something beyond mere mechanism at the
    > bottom of it.

    _Art and Photography_, in [_The New Path_ Vol. 2, No. 12
    (1865-12-01)][tnp], pp. 198-199

[tnp]: https://www.jstor.org/stable/20542505

The concerns and criticisms currently being directed towards AI-generated art
are the same as those leveled against photography in the past. And just as
photography eventually gained acceptance as a valid form of art so will
AI-generated art. The resistance against it may be strong, but ultimately, it
is a losing battle.

## My Family's Art

My family has a long history of painting. My great-great-great grandfather was
the Norwegian landscape painter [Hans Gude][hans_gude]. My father, also named
[Hans Gude][hans_gude_2], was [an accomplished oil
painter][painter].[^hans_art] I too wanted to make art, but I did not have
their skill with a brush so I picked up a camera instead.

[hans_gude]: https://en.wikipedia.org/wiki/Hans_Gude
[hans_gude_2]: https://www.hfgudeart.com/about2
[painter]: https://www.hfgudeart.com/

[^hans_art]:
    My father somewhat rejected the title of "artist", although in later life
    he branded himself as such. He prefered to think of himself as a
    craftsman, honing his skills through hardwork and study.

I was drawn to photography **specifically because** it used technology. I like
learning new technologies and how to master them. I _also_ thought it would be
easier to make art I was happy with using a camera. I have since learned that
photography has its own set of skills to master, but after 15 years I think I
was mostly right: it is much easier than oil painting.

I wonder what my great grandfather would think of my art. He spent months or
years creating his seascapes, while my photographs are captured in a fraction
of a second with the push of a button, and maybe a few hours adjusting tone
curve and highlights back at my computer.

But I like to think that he would view my work as a continuation of our
family's artistic tradition. Maybe in the future, my descendants will find the
camera too complicated and instead compose prompts for AI to translate into
images. To me, that's simply another evolution of the art form.
