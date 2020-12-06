---
layout: post
title: "Using Travis Build Stages to Test Multiple Python Versions and Publish
to Pypi"
description: >
  Often when building packages, we want to test against multiple versions of
  the language, and then build the package once. I will show you how to accomplish this using
  Travis Stages.
image: /files/travis/us_airforce_construction_by_sue_sapp.jpg
show_lead_image: True
image_alt: >
  A construction site with the metal frame of a building and various pieces of
  heavy equipment parked around it.
categories:
  - python
  - software-development
---

{% capture file_dir %}/files/travis/{% endcapture %}

I recently finished a new Python program, [`wayback-machine-archiver`][wbma].
See my [recent post for details][wbma_post]. It supports **many** different
versions of Python,[^1] which required me to [automate the build system][ab].
I needed my build system to:

- Install the software for each supported Python version.
- Run tests against each Python version.
- Publish **_exactly once_** to [Pypi][wbma_pypi] when all the tests in all
the Python versions had passed.

[wbma]: https://github.com/agude/wayback-machine-archiver
[wbma_post]: {% post_url 2019-06-04-wayback_machine_archiver %}
[ab]: https://en.wikipedia.org/wiki/Build_automation
[wbma_pypi]: https://pypi.org/project/wayback-machine-archiver/

Running a bunch of tests, and then deploying your software is exactly what
[Travis Stages][travis_stages] were designed for. There was just one problem:
I couldn't find a good example of how to do it with multiple Python versions.
This post will explain how to do it.

[travis_stages]: https://docs.travis-ci.com/user/build-stages/

## The Travis Configuration

Here is the full [Travis Configuration file][config]. I'll go through a
simplified version below that covers just the essentials:

[config]: https://github.com/agude/wayback-machine-archiver/blob/b3d0955e03a09662c1eb9ea962e527a8299bc209/.travis.yml

### Run Tests in Parallel

We start by setting up the Python versions to use for testing:

```yaml
language: python
dist: xenial # Required for Python >= 3.7
python:
  - "2.7" 
  - "3.7"
  # Also test pypy
  - "pypy3"
```

This will run tests in parallel on Python 2.7, 3.7, and [Pypy3][pypy]. Python
3.7 is [only supported on Ubuntu Xenial][supported], so we set that as the
`dist`. I removed a bunch of version for clarity; to add more, just write them
in the list.

[supported]: https://docs.travis-ci.com/user/languages/python/#python-37-and-higher

Next, we tell Travis how to set up the environment and test the code: 

```yaml
install:
  - pip install -r requirements.txt
script:
  # Unit tests
  - python -m pytest -v
  # Install and smoke test
  - pip install .
  - archiver --help
```

This installs the dependencies, runs the unit tests, makes
sure we can pip install the package, and finally runs a quick ["smoke test"][smoke] on
the installed package.

[smoke]: https://en.wikipedia.org/wiki/Smoke_testing_(software)

### Build and Deploy

After the tests succeed (and _only_ after) we build the Pypi package:

```yaml
jobs:
  include:
    - stage: build
      python: "3.7"
      script: echo "Starting Pypi build"
      deploy:
        provider: pypi
        user: alexgude
        password:
          secure: Bq6I8x...sqslR  # Hashed password
        distributions: "sdist bdist_wheel"
        on:
          tags: true
          branch: master
          repo: agude/wayback-machine-archiver
        skip_existing: true
```

This defines a new stage to build the package in 3.7 and then deploys it to
Pypi, but only if it is the master branch on a tagged (from [`git
tag`][tag]) release.

[tag]: https://git-scm.com/book/en/v2/Git-Basics-Tagging

Which gives us this:[^2]

[![A screen shot of the resulting Travis run from this
configuration file.][result_png]][result_png]

[result_png]: {{ file_dir }}/results.png

I hope that helps you set up your own Python packages for testing and
deployment! In the future, I hope to migrate to [Github
Actions][github_actions], but that is for another time.

[github_actions]: https://github.com/features/actions

---

[^1]: Currently 2.7, 3.4 through 3.7, the development versions of 3.7 and 3.8, the nightly release, and [pypy 2.7 and 3.5][pypy].

[pypy]: https://pypy.org/

[^2]: I took out a bunch of the versions in the example YAML configuration; the screen shot shows all the versions I test against.
