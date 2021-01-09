IMAGE := jekyll-image-agude
MOUNT := /workspace

.PHONY: all serve drafts debug image refresh

all: serve

# Serve the site as it will appear when published.
serve: image
	docker run --rm -p 4000:4000 -v $(PWD):$(MOUNT) -w $(MOUNT) $(IMAGE) bundle exec jekyll serve

# Serve the site but also publish drafts.
drafts: image
	docker run --rm -p 4000:4000 -v $(PWD):$(MOUNT) -w $(MOUNT) $(IMAGE) bundle exec jekyll serve --drafts

# Interactive session within the image so you can poke around.
debug: image
	docker run -it --rm -p 4000:4000 -v $(PWD):$(MOUNT) -w $(MOUNT) $(IMAGE)

# Don't send the whole repo to Docker. All we need is the Gemfile.
BUILDDIR := /tmp/jekyll-docker-agude

image: Dockerfile Gemfile
	rm -rf $(BUILDDIR)
	mkdir -p $(BUILDDIR)
	cp Gemfile $(BUILDDIR)
	docker build $(BUILDDIR) -f Dockerfile -t $(IMAGE)

# Rebuilding from halfway using a cached image can sometimes cause
# problems. Use `make refresh` to rebuild the image from the ground up.
refresh: Dockerfile Gemfile
	rm -rf $(BUILDDIR)
	mkdir -p $(BUILDDIR)
	cp Gemfile $(BUILDDIR)
	docker build $(BUILDDIR) -f Dockerfile -t $(IMAGE) --no-cache
