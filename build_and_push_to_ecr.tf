# Build and push the Docker image whenever the Dockerfile or src or bin file hashes change
resource "null_resource" "build_and_push_to_ecr" {
  triggers = {
    # For every file in ./bin, calculate the SHA256
    bin_hashes = jsonencode({
      for file_name in fileset("${path.module}/bin", "**") : file_name => filesha256("${path.module}/bin/${file_name}")
    })
    # For every file in ./src, calculate the SHA256
    src_hashes = jsonencode({
      for file_name in fileset("${path.module}/src", "**") : file_name => filesha256("${path.module}/src/${file_name}")
    })
    # Calculate the SHA256 of the Dockerfile
    dockerfile_hash = filesha256("${path.module}/Dockerfile")
  }

  provisioner "local-exec" {
    # aws ecr get-login-password | docker login --username AWS --password-stdin "$2" && docker build -t "$3:$2" $1 && docker push "$3:$2"
    # ./build_and_push_to_ecr.sh . 1234567890.dkr.ecr.us-east-2.amazonaws.com/ecr_repo_name:docker_image_tag
    command     = "${path.module}/build_and_push_to_ecr.sh ${path.module} ${aws_ecr_repository.quest_ecr.repository_url} ${var.docker_image_tag}"
    interpreter = ["bash", "-c"]
  }

  depends_on = [aws_ecr_repository.quest_ecr]
}
