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

I spent a lot of time cleaning up the [California Statewide Integrated Traffic
Records System (SWITRS)][switrs] dataset for use in my own projects. I even
wrote a [helpful script][s2s] to do so automatically. I thought that would
make it easy for others to use the data, but no. They still had to request the
data, download it, and then run the scripts. Worse, some of the old data was
no longer available.

[switrs]: http://iswitrs.chp.ca.gov/Reports/jsp/userLogin.jsp
[s2s]: {% post_url 2016-11-01-switrs_to_sqlite %}
[sqlite]: https://en.wikipedia.org/wiki/SQLite

I decided to [create a clean dataset and host it][hosted_dataset_post] so that
people could start using it immediately. Unfortunately, the data was pretty
large, so finding a site to host it was not easy. In the end I choose two
places: [**Kaggle**][db_link] and [**Zenodo**][zen_link]. In this post I'll
share the lessons I learned, the benefits of each site, and why I think using
both is the right thing to do.

[hosted_dataset_post]: {% post_url 2020-11-24-switrs_sqlite_hosted_dataset %}
[db_link]: https://www.kaggle.com/alexgude/california-traffic-collision-data-from-switrs
[zen_link]: https://zenodo.org/record/4284843

## Requirements?

- FREE
- EASY
- SOMEWHERE PEOPLE COULD FIND IT

## Kaggle

Kaggle is a great place to host a dataset. It allows users to download the
file _or_ work with the data directly in Kaggle's hosted notebooks. The author
can even set up a [demo notebook][demo_nb] to demonstrate how to work with the
data. Kaggle will even help you set up a [DOI][doi] for your data. Mine is:
[10.34740/kaggle/dsv/1671261][my_doi]

[demo_nb]: https://www.kaggle.com/alexgude/starter-california-traffic-collisions-from-switrs
[doi]: https://en.wikipedia.org/wiki/Digital_object_identifier
[my_doi]: https://www.doi.org/10.34740/kaggle/dsv/1671261

Kaggle supports really deep data documentation. You can write an introduction
for each table and each column. Additionally, Kaggle will automatically
generate histograms of each column and some summary statistics.

Kaggle is more than just hosting; it is a community. Other people can
share their work, set up challenges using the data, and ask questions in the forum, and

Kaggle does have some significant downsides though. First, users must create
an account to download the data. Second, Kaggle is a for-profit company that
is famous for dropping support for their products. I don't trust them to host
the data long term.

### Pros

- Free for you and me
- Community
  - Forums
  - Challenges
- Great docs
- Built in compute
  - Demo notebook
- DOI
- Versioning
- Activity feed

### Cons

- Google is infamous for [shutting stuff down][killedbygoogle]
- Account required


## Zenodo

Zenodo---hosted by CERN---is a much simpler and smaller service than Kaggle.
It does not a community built up around it. It does not have attached cloud
compute. They have almost no users.[^usage]

So why use Zenodo? Simple: Google is infamous for [killing
products][killedbygoogle] while CERN knows a little something about [keeping
websites online][first_site]. I trust CERN's stewardship of the dataset. I am
far more confident that you will be able to download it from Zenodo in 10
years than from Kaggle.

[killedbygoogle]: https://killedbygoogle.com/
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

---

[^usage]: As of this post, my dataset has been viewed 161 times on Zenodo and
    downloaded just 47 times. It has been viewed 47,800 times on Kaggle and
    downloaded 3017 times. In addition, there have been 24 Kaggle notebooks
    posted that make use of the data.
