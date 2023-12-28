all: build_wren

generate_bindings:
	shards install
	./bin/libgen wren.yml

build_wren:
	./src/ext/generate.sh
