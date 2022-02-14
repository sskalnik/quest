data "aws_region" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "random_shuffle" "get_a_random_az" {
  input        = data.aws_availability_zones.available.names
  result_count = 1
}

data "aws_vpc" "vpc" {
  id = var.vpc_id
}


# If no public subnet(s) provided via input variables, create a public subnet
resource "aws_subnet" "quest_public_subnet" {
  # If the length of the list `var.public_subnet_ids` is a non-zero number (i.e., a list of subnet IDs was passed in via input variables):
  #   Do not create this resource
  # Else
  #   Create a public subnet
  count = length(var.public_subnet_ids) > 0 ? 0 : 1

  vpc_id                  = var.vpc_id
  cidr_block              = cidrsubnet(data.aws_vpc.vpc.cidr_block, 4, 1)
  availability_zone       = random_shuffle.get_a_random_az.result
  map_public_ip_on_launch = true
}


# Create an AWS ECR (Elastic Container Repository) to store the Docker container(s)
resource "aws_ecr_repository" "quest_ecr" {
  name = "quest_ecr"

  # Needed in order to put the latest tag on a given container image
  image_tag_mutability = "MUTABLE"

  # Scan all container images for security issues/vulnerabilities as soon as the images are pushed to the repo
  image_scanning_configuration {
    scan_on_push = true
  }
}


# This is overkill for a take-home test, but best practices and all that...
# No reason for 16 images... I just picked an arbitrary power of 2.
resource "aws_ecr_lifecycle_policy" "only_keep_last_16_images" {
  repository = aws_ecr_repository.quest_ecr.name

  policy = jsonencode({
   rules = [{
     rulePriority = 1
     description  = "Only keep last 16 images in ECR. No reason for 16... the dev just picked an arbitrary power of 2."
     action       = {
       type = "expire"
     }
     selection     = {
       tagStatus   = "any"
       countType   = "imageCountMoreThan"
       countNumber = 16
     }
   }]
  })
}


# Create an AWS ECS Cluster where the ECS/Fargate Tasks will run
resource "aws_ecs_cluster" "quest_cluster" {
  name = "quest_cluster"
}

resource "aws_ecs_task_definition" "quest_ecs_fargate_task" {
  family                   = "quest_ecs_fargate_task"
  container_definitions    = <<DEFINITION
  [
    {
      "name": "quest_ecs_fargate_task",
      "image": "${aws_ecr_repository.quest_ecr.repository_url}",
      "essential": true,
      "portMappings": [
        {
          "containerPort": 3000,
          "hostPort": 3000
        }
      ],
      "memory": 512,
      "cpu": 256
    }
  ]
  DEFINITION
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"    # Required for Fargate!
  memory                   = 512         # This must match the "memory" value from the `container_definitions` block above!
  cpu                      = 256         # This must match the "cpu" value from the `container_definitions` block above!
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn # ECS Service uses this Role
  task_role_arn            = aws_iam_role.quest_ecs_fargate_task_role.arn # The Tasks themselves use this Role (similar to EC2 Instance Profile)
}


resource "aws_security_group" "quest_ecs_service_sg" {
  description =  "Only allow incoming traffic from the ALB in front of the ECS Service"

  vpc_id = var.vpc_id

  ingress {
    # Assume port 3000 for the containers/Tasks
    from_port       = 3000
    to_port         = 3000
    protocol        = "-1"
    # Only allow incoming traffic from the ALB in front of the ECS Service
    security_groups = [aws_security_group.quest_alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    #tfsec:ignore:AWS009
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# The ECS Service definition ties all of the above resources together
resource "aws_ecs_service" "quest_ecs_service" {
  name            = "quest_ecs_service"
  cluster         = aws_ecs_cluster.quest_cluster.id
  task_definition = aws_ecs_task_definition.quest_ecs_fargate_task.arn
  launch_type     = "FARGATE"
  desired_count   = var.ecs_service_desired_task_count

  network_configuration {
    # Either use the input variable var.public_subnet_ids, or use a singleton list containing the ID of a public subnet that is only created when none are input.
    subnets          = length(var.public_subnet_ids) > 0 ? var.public_subnet_ids : [aws_subnet.quest_public_subnet.id]
    # Please don't dock too many points for the following potential security issue 🥺👉🏽👈🏽
    assign_public_ip = true # Required for Fargate + ECR: https://aws.amazon.com/premiumsupport/knowledge-center/ecs-pull-container-api-error-ecr/
    security_groups  = [aws_security_group.quest_ecs_service_sg.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.quest_alb_target_group.arn
    container_name   = aws_ecs_task_definition.quest_cluster.family
    container_port   = 3000
  }
}

# Set up an AWS Application Load Balancer to accept edge Internet traffic and load balance between the ECS/Fargate Tasks (containers)
#tfsec:ignore:AWS005
resource "aws_alb" "quest_alb" {
  name               = "quest_alb"
  load_balancer_type = "application"
  subnets            = var.public_subnet_ids
  security_groups    = [aws_security_group.quest_alb_sg.id]
}


resource "aws_lb_target_group" "quest_alb_target_group" {
  name        = "quest-alb-target-group" # The fact that this field can include hyphens but not underscores is a source of great ire...
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  health_check {
    matcher = "200,301,302"
    path = "/"
  }
}


resource "aws_lb_listener" "quest_alb_listener_http" {
  load_balancer_arn = aws_alb.quest_alb.arn
  port              = 80
  #tfsec:ignore:AWS004
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.quest_alb_target_group.arn
  }
  # TODO: set up TLS using an ACM Cert
  # default_action {
  #   type = "redirect"
  #
  #   redirect {
  #     port        = 443
  #     protocol    = "HTTPS"
  #     status_code = "HTTP_301"
  #   }
  # }
}

# TODO: set up TLS using an ACM Cert
# resource "aws_alb_listener" "https" {
#   load_balancer_arn = aws_lb.quest_alb.id
#   port              = 443
#   protocol          = "HTTPS"
#
#   ssl_policy        = "ELBSecurityPolicy-2016-08"
#   certificate_arn   = TODO
#
#   default_action {
#     target_group_arn = aws_alb_target_group.quest_alb_target_group.arn
#     type             = "forward"
#   }
# }


resource "aws_security_group" "quest_alb_sg" {
  description = "Allow HTTP 80 TCP and HTTPS 443 TCP incoming to the ALB. Allow any outgoing traffic."

  vpc_id = var.vpc_id

  ingress {
    description = "Allow incoming HTTP 80 TCP from anywhere (public Internet) to the ALB."
    from_port   = 80
    to_port     = 80
    protocol    = "-1"
    #tfsec:ignore:AWS008
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow incoming HTTPS 443 TCP from anywhere (public Internet) to the ALB."
    from_port   = 443
    to_port     = 443
    protocol    = "-1"
    #tfsec:ignore:AWS008
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow any/all outgoing traffic from the ALB (including to the public Internet)."
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    #tfsec:ignore:AWS009
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# The ECS/Fargate Task(s) will use the following IAM Role for any interactions with other AWS resources.
# This is analogous to an EC2 Instance's Instance Profile.
resource "aws_iam_role" "quest_ecs_fargate_task_role" {
  name_prefix        = "quest_ecs_fargate"
  assume_role_policy = data.aws_iam_policy_document.quest_ecs_fargate_task_role_policy_document.json
}

data "aws_iam_policy_document" "quest_ecs_fargate_task_role_policy_document" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      identifiers = ["ecs-tasks.amazonaws.com"]
      type        = "Service"
    }
  }
}


# Boilerplate code to set up the AWS Service Role "ecsTaskExecutionRole" and its related Policies
# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_execution_IAM_role.html
resource "aws_iam_role" "ecsTaskExecutionRole" {
  name               = "ecsTaskExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.ecsTaskExecutionRole_assume_role_policy_document.json
}

data "aws_iam_policy_document" "ecsTaskExecutionRole_assume_role_policy_document" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ecsTaskExecutionRole_policy" {
  role       = aws_iam_role.ecsTaskExecutionRole.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

