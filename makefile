.PHONY: test bench docs check

test:
	mops test

check:
	find src -type f -name '*.mo' -print0 | \
	xargs -0 $(shell mops toolchain bin moc) -r $(shell mops sources) -Werror -wasi-system-api

bench:
	mops bench  --gc incremental%