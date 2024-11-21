all: clean deps shellcheck test build
deps:
	@wget https://raw.githubusercontent.com/system4-tech/utils-sh/refs/heads/main/lib/utils.sh -qO lib/utils.sh
build:
	@awk -f inline.awk src/main.sh > lib/binance.sh
clean:
	@rm -f lib/*.sh
test:
	@bats tests/*.bats
shellcheck:
	@shellcheck src/*.sh examples/*.sh

