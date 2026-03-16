build:
	bash scripts/build.sh

run: build
	bash scripts/run.sh

clean:
	rm -rf build
