.PHONY: check flake8 jshint

all: clean flake8 jshint

clean:
	find -name "*.pyc" | xargs rm -f
	rm -rf cache/*

flake8:
	flake8 --max-line-length=120 --ignore=E123,E124,E128,E251 etalagepassim

jshint:
	jshint etalagepassim/static/js/*.js
