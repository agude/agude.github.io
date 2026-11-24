# Strict Liquid Include Parameters

Under strict Liquid, pass every parameter an include reads at the call site.
When an include is called with no parameters, the `include` object is
undefined; even `include.foo | default: false` fails before the filter runs.

For example, pass `standalone` explicitly:

```liquid
{% include markdown_alternate_link.html standalone=false %}
```

