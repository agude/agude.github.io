---
layout: default
title: OMEMO Fingerprints
description: >
  Alex Gude's OMEMO fingerprints and QR codes for secure messaging.
sidebar_include: false
date: 2025-02-02
omemo_fingerprints:
  - device_name: Android Conversations
    fingerprint: 7d417976 4886dae0 f784fe0f a40cf355 8ed5a040 2dc08dfd ff75a232 a29d9848
    qr_code: /files/omemo/android-omemo-qr.png
  - device_name: Linux Desktop Gajim
    fingerprint: 3937481a 47924f9f 70bebdc8 d7668596 c5ab7de1 e1e75d18 7cc10999 f57f895c
    qr_code: /files/omemo/linux-omemo-qr.png
  - device_name: MacOS Laptop BeagleIM
    fingerprint: fdac370e 471001d9 73d7cb48 5b742a32 2a693ab4 bd41f076 2a905b3e a813cf4b
    qr_code: null
---

# {{ page.title }}

Below are my OMEMO fingerprints and their corresponding QR codes (where
available) for secure messaging as of <time datetime="{{ page.date |
date_to_xmlschema }}">{{ page.date | date: "%B %-d, %Y" }}</time>. These
fingerprints are used to verify the identity of my devices in end-to-end
encrypted communication.

{% for device in page.omemo_fingerprints %}
## {{ device.device_name }}

**Fingerprint:** `{{ device.fingerprint }}`

  {% if device.qr_code %}
**QR Code:** ![{{ device.device_name }} OMEMO QR Code]({{ device.qr_code }}){: .omemo-qr-code }
  {% else %}
**QR Code:** *No QR code available for this device.*
  {% endif %}

{% endfor %}
