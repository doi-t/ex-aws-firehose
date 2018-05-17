FUNCTION=ex-aws-firehose

all: build apply

.PHONY: clean build apply test

clean:
	rm -rf build
	rm -rf tmp
	rm -rf lambda/.mypy_cache/

# Ref. https://gist.github.com/istepanov/48285351fa206a0aba92615fb9d632c6
build:
	mkdir -p build/site-packages
	cd ./lambda; zip -r ../build/$(FUNCTION).zip . -x "requirements.txt" "*.mypy_cache*" "*__pycache__*"
	python3 -m venv build/$(FUNCTION)
	. build/$(FUNCTION)/bin/activate; \
	pip3 install  -r requirements.txt; \
	cp -r $$VIRTUAL_ENV/lib/python3.6/site-packages/ build/site-packages
	cd build/site-packages; zip -g -r ../$(FUNCTION).zip . -x "*__pycache__*"

apply:
	./apply.sh

test:
	./put_test_log_to_log_stream.sh
