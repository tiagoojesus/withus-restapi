# to run the commands below, i a shell do:
# make compile
## or
# make build
## or
# make build-debug

# each command has the form
# <command name>:
# <tab> <command to execute>


# Define variables
IMAGE_NAME:=restapi
TAG:=latest

compile:
	go build

build:
	docker build --network host -t $(IMAGE_NAME) .

build-debug:
	docker build --network host --no-cache --progress=plain -t $(IMAGE_NAME) .

run-shell:
	docker run --entrypoint sh -it --rm $(IMAGE_NAME)

.PHONY: all
all: build







