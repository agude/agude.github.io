---
layout: post
title: "Where to Host Public Datasets?"
description: >
  When I released the SWITRS dataset, I had to find a place to host a 5 Gig
  dataset. Here is what I learned.
image: /files/switrs-dataset/doe_computer.jpg
image_alt: >
  An overhead photo of a Department of Energy supercomputer showing the
  ethernet interconnects.
categories: 
  - california-traffic-data 
  - data-science
---

{% capture file_dir %}/files/switrs-dataset{% endcapture %}

Cleaning a dataset is tough work. I spent weeks figuring out what all the
columns of the [California Statewide Integrated Traffic Records System
(SWITRS)][switrs] dataset meant and additional time [writing scripts to parse
and fix it][s2s]. I wanted other people to be able to make use of the data
without going through the same hassle, so I released the scripts.

[switrs]: http://iswitrs.chp.ca.gov/Reports/jsp/userLogin.jsp
[s2s]: {% post_url 2016-11-01-switrs_to_sqlite %}

It wasn't enough. People still had to request the data, download it, and then
run the scripts. Too much of a hurdle for most people. And worse, California
no longer provided some of the oldest data. It was suddenly impossible for
other people to reproduce my earlier work!

[sqlite]: https://en.wikipedia.org/wiki/SQLite

Luckily, I had saved all of the data. So I decided to [host the dataset
online][hosted_dataset_post] to make it easy to start using right away.

But there was a problem: the dataset was so large that finding a site to host
it was not easy. In the end I choose two places: [**Kaggle**][db_link] and
[**Zenodo**][zen_link]. In this post I'll share the lessons I learned, the
benefits of each site, and why I think using both is the right thing to do.

[hosted_dataset_post]: {% post_url 2020-11-24-switrs_sqlite_hosted_dataset %}
[db_link]: https://www.kaggle.com/alexgude/california-traffic-collision-data-from-switrs
[zen_link]: https://zenodo.org/record/4284843

## My Requirements

I had four requirements:

- **Free**: The service had to be free for me, and free for the end users as
  well. Requiring someone to pay for access to an open source dataset that I
  had volunteered to curate is unfair and would certainly drastically reduce
  the number of people making use of it.

- **Easy**: It had to be easy for me to set up. I wanted a service where I
  could get started without having to email someone for permission. I also
  wanted it to be easy for the end user to get the data so that the largest
  number of people could make use of it.

- **Discoverable**: It was important to me that people could easily find the
  dataset. There are dozens of sites that host large files, but they aren't
  places where people would go look for data. To help people find it I would
  have to set up a web page pointing to the download, which wasn't something I
  wanted to maintain.

- **Permanent**: Finally, there was no point in going through all this work if
  it was just going to disappear tomorrow. I wanted the data to be available
  for years and years.

[AWS Open Data][aws] was one option I considered, but it looked like a lot of
work to set up and it was unclear exactly how free it was. Further, getting
the data wasn't easy if you had never worked with S3 before. Ideally, I wanted
a service that had a big button that said "Download this data!"

[aws]: https://aws.amazon.com/opendata

I also considered self-hosting on [my Raspberry Pis][pi], but quickly
dismissed it. Availability would be terrible, download speeds would be even
worse, and it would force me to perform a lot of maintenance to keep it
running.

[pi]: {% post_url 2017-11-13-raspberry_pi_reboot_times %}

In the end I settled on two services:

## Kaggle

Kaggle is a great place to host a dataset. It's free, easy to use (with the
exception that you need an account), and is a well known place to find
datasets making it discoverable. The one downside is that Google is [infamous
for killing services][killedbygoogle], so the data might not last.

[killedbygoogle]: https://killedbygoogle.com/

Kaggle allows users to download the file _or_ work with the data directly in
Kaggle's hosted notebooks. The author can even set up a [demo
notebook][demo_nb] to demonstrate how to work with the data. Kaggle will even
help you set up a [DOI][doi] for your data. Mine is:
[10.34740/kaggle/dsv/1671261][my_doi]

[demo_nb]: https://www.kaggle.com/alexgude/starter-california-traffic-collisions-from-switrs
[doi]: https://en.wikipedia.org/wiki/Digital_object_identifier
[my_doi]: https://www.doi.org/10.34740/kaggle/dsv/1671261

Kaggle supports really deep data documentation. You can write an introduction
for each table and each column. Additionally, Kaggle will automatically
generate histograms of each column and some summary statistics.

Kaggle is more than just hosting; it is a community. Other people can share
their work, set up challenges using the data, and ask questions in the forum.
This community makes it easy for people to find the data and get started
working with it.

## Zenodo

Zenodo---hosted by CERN---is a much simpler and smaller service than Kaggle.
It does not hat a community built up around it. It does not have attached
cloud compute. They have almost no users.[^usage]

[^usage]: As of this post, my dataset has been viewed 161 times on Zenodo and
    downloaded just 47 times. It has been viewed 47,800 times on Kaggle and
    downloaded 3017 times. In addition, there have been 24 Kaggle notebooks
    posted that make use of the data.

So why use Zenodo? Simple: Google [kills products left and
right][killedbygoogle] while CERN knows a little something about [keeping
websites online][first_site]. I trust CERN's stewardship of the dataset. I am
far more confident that you will be able to download it from Zenodo in 10
years than from Kaggle.

[first_site]: http://info.cern.ch/

Zenodo has great support for academic dataset usage. It allows you to use any
valid DOI, so I was able to reuse the one from Kaggle, although it will also
generate one for you if you wish. It will track citations to your dataset and
provides links to the papers. It will even let you export the citation to
[BibTex][bibtex] or generate a text citation on the website. Zenodo lets you
link your identity to your [Open Researcher and Contributor ID][orcid].

[bibtex]: https://en.wikipedia.org/wiki/BibTeX
[orcid]: https://en.wikipedia.org/wiki/ORCID

Unlike Kaggle, Zenodo makes downloading easy. You do not need an account, you
just go to the page and click the download button. It also shows a [MD5
hash][md5] of the file so you can verify your download is exactly the same as
the file on the server.

[md5]: https://en.wikipedia.org/wiki/MD5

Zenodo has a problem in addition to its low usage though: uploading a dataset
often fails. I originally tried to upload the uncompressed database but that
failed multiple times. After reaching out to their support (who were very
responsive and helpful), I compressed the database tried again. The smaller
file succeed where the larger one had failed.

## Conclusion

I think using both Kaggle and Zenodo is the perfect way to host a public
dataset. Kaggle has a great community and lets people quickly discover your
dataset and make use of it. The downside is the uncertain longevity and the
fact that you need an account to download the dataset. Zenodo perfectly
complements Kaggle's weakness as its backed by CERN, an organization that
takes data hosting seriously, and makes it very easy to download the dataset.
