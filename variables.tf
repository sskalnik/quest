variable "vpc_id" {
  type        = string
  description = "ID of a VPC in which to deploy the ECS cluster, ALB, etc."

  validation {
    condition     = can(regex("^[0-9a-z\\-]+[0-9a-z]$", var.vpc_id))
    error_message = "\"vpc_id\" can only contain lower case letters, numbers, and hyphens!"
  }
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "List of subnet IDs in which to deploy the ALB which will accept traffic going to the ECS cluster. If left blank, this Terraform code will create public subnets!"
  default     = []
}

variable "ecs_service_desired_task_count" {
  type        = number
  description = "Number of ECS/Fargate Tasks (read: Docker/containerd containers) to deploy in the ECS Cluster, similar to EC2 Instance count in an ASG."
  default     = 3 # Good rule of thumb number for fault tolerance, demonstrating scaling up and down, and preventing split-brain and/or election problems.
}

variable "docker_image_tag" {
  type        = string
  description = "String with which the Docker image will be tagged when pushed to ECR."
  default     = "latest"
}

variable "root_domain_name" {
  type        = string
  description = "Root domain name, such as `example.com`, for which TF will generate an ACM cert and a CF distribution."
  default     = "rearc.homewor.cc"
}
