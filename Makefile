default: localbuild

mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
current_dir := $(realpath $(dir $(mkfile_path)))
dev:
	docker run --rm -v $(current_dir):/srv/jekyll:Z -p 127.0.0.1:4000:4000/tcp jekyll/jekyll jekyll serve

localbuild:
	docker run -v $(current_dir):/srv/jekyll -v $(current_dir)/_site/:/srv/jekyll/_site jekyll/builder:latest /bin/bash -c "chmod -R 777 /srv/jekyll && jekyll build --future"

dev-arm-install:
	bundle install

dev-arm:
	bundle exec jekyll serve