#!/bin/bash


function tag_and_pull {
	if [ -n "$1" ] && [ -n "$IMAGE_NAME" ]; then
		echo "Pulling docker image from hub tagged as $IMAGE_NAME:$1"
		
		docker pull $IMAGE_NAME:$1
	fi
}
	cat > ~/.dockercfg <<EOF
{
  "https://index.docker.io/v1/": {
    "auth": "${HUB_AUTH}",
    "email": "${HUB_EMAIL}"
  }
}
EOF
	if [ -n "$TRAVIS_TAG" ]; then
		tag_and_push $MAJOR_TAG
		tag_and_push $VERSION_TAG
	elif [[ "${TRAVIS_BRANCH}" =~ release-.+ ]]; then
		tag_and_push $TRAVIS_BRANCH
	elif [ "${TRAVIS_BRANCH}" = "master" ]; then
		tag_and_push $LATEST_TAG
	fi
else
	echo "No image to build"
fi
