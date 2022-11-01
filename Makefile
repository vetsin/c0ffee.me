default: localbuild

localbuild:
	docker run -v $(pwd):/srv/jekyll -v $(pwd)/_site/:/srv/jekyll/_site jekyll/builder:latest /bin/bash -c "chmod -R 777 /srv/jekyll && jekyll build --future"
