---
layout: post
title: "Using Travis Build Stages to Test Multiple Versions"
description: >
  Often when building packages, we want to test against multiple versions of
  the language, and then build the package once. I will show you how using
  Travis Stages.
image: /files/data-science-testing/brick_header.jpg
image_alt: >
  A pile of worn bricks covered in dust and chips of other bricks.
---

{% include lead_image.html %}

I recently finished a new Python program, [`wayback-machine-archiver`][wbma].
See my [recent post for details][wbma_post]. It supports **many** different
versions of Python[^1], which required me to [automate the build system][ab].
I needed my build system to:

- Install the software for each supported Python version.
- Run tests against each Python version.
- Publish **_exactly once_** to [Pypi][wbma_pypi] when all the tests in all
the Python versions had passed.

[wbma]: https://github.com/agude/wayback-machine-archiver
[wbma_post]: {% post_url 2019-06-04-wayback_machine_archiver %}
[ab]: https://en.wikipedia.org/wiki/Build_automation
[wbma_pypi]: https://pypi.org/project/wayback-machine-archiver/

Running a bunch of tests, and then deploying you software is exactly what
[Travis Stages][travis_stages] were designed for. There was just one problem:
I couldn't find a good example of how to do it with multiple Python versions.
This post will explain how to do it.

[travis_stages]: https://docs.travis-ci.com/user/build-stages/

## The Travis Configuration

Here is the full [Travis Configuration file][config]. I'll go through a
simplified version below:

[config]: https://github.com/agude/wayback-machine-archiver/blob/b3d0955e03a09662c1eb9ea962e527a8299bc209/.travis.yml

First, we set up the Python versions to use for testing:

```yaml
language: python
dist: xenial # Required for Python >= 3.7
python:
  - "2.7" 
  - "3.7"
  # Also test pypy
  - "pypy3"
```

This will run tests in paralell on Python 2.7, 3.7, and [Pypy3][pypy].

```yaml
install:
  - pip install -r requirements.txt
  - pip install pypandoc
addons:
  apt_packages:
    - pandoc  # Required to convert the README to a Pypi description
script:
  - python -m pytest -v
  - pip install .
  - archiver --help

# The default job (above) is the test job, the package build job is specified below
jobs:
  include:
    - stage: build
      python: "3.7"
      script: echo "Starting Pypi build"
      deploy:
        provider: pypi
        user: alexgude
        password:
          secure: Bq6I8x+9K99zWucn+zqkFzB2snyftI2vXqhHTFiJthyzQYsX1FlOB9muVsmcNEFi9I/100tGwPNBKa/oAtGfE55wzzqTiFRQ3XqT/JPkk5l+mvPlCKM3NsqslR/EPmanecLdaceCHboHOQy34tAHAjyjD3vsqvsqOMIo8UNItUeR5diIG4pUEaN1rBa8wmn1SHhUK9n746qLKHuUSknSybSaZJUsjnOy6eZnCpZ3NVlZLLNjKtZmcyX4LwGI7+Oxj/Ag0iEnJ/6tTB1Bl/0lLzQNk5hqQOv9jEG2pQ4+hK5Oa/exaj/kJFE8+odx9iM33o9ZWHOXwptQeyPfF/2Wefj7t519fubqND/JHanN3NMzx6KTdBqwv2KLnvgt+dx1URc3VMSp4dNPgeNfbqlOCDjCVWrYdxEtn7s2vsAw+mAFYRXcppCzjWsXBlRFwCU6g98JuPncY6XsFZ1TrI2IdUnB8+MaHRXFzxuEhRt3ygOfnAGzAVhLuhercOBvGJ8JaVofNi+2JwtVX/h/ImwwufRnZRyfw5ICsSEzGVxZGho7VawmywxFAjptIe6CZl/JhoZFfTU/z8TgRiIPMM8C3Sc1ntZF4JmLu6Vg3U/QQliFXbpNSyOyChlWLzexrvYsKcdXThfjk5qQAiW9syBR8jfCHBEkNmj2MXVWrgYVGw4=
        distributions: "sdist bdist_wheel"
        on:
          tags: true
          branch: master
          repo: agude/wayback-machine-archiver
        skip_existing: true
```


---

[^1]: Currently 2.7, 3.4 through 3.7, the development versions of 3.7 and 3.8, the nightly release, and [pypy 2.7 and 3.5][pypy].

[pypy]: https://pypy.org/
