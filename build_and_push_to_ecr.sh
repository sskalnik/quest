#!/bin/bash -xe

# aws ecr get-login-password | docker login --username AWS --password-stdin 152186773809.dkr.ecr.us-east-2.amazonaws.com/quest_ecr
# docker build -t latest .
# docker push
aws ecr get-login-password | docker login --username AWS --password-stdin "$2" && docker build -t "$2:$3" $1 && docker push "$2:$3"

#docker_image_source_path="$1"
#ecr_url="$2"
#image_name_with_tag="$3"

#region="$(echo "$repository_url" | cut -d. -f4)"
#image_name="$(echo "$repository_url" | cut -d/ -f2)"

#(cd "$source_path" && docker build -t "$image_name" .)

#aws ecr get-login-password --region "$region" | docker login --username AWS --password-stdin "$repository_url"
#docker tag "$image_name" "$repository_url":"$tag"
#docker push "$repository_url":"$tag"
