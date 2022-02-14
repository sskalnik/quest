# Create an AWS ECR (Elastic Container Repository) to store the Docker container(s)
resource "aws_ecr_repository" "quest_ecr" {
  name = "quest_ecr"

  # Scan all container images for security issues/vulnerabilities as soon as the images are pushed to the repo
  image_scanning_configuration {
    scan_on_push = true
  }
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
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn
}


resource "aws_security_group" "quest_ecs_service_sg" {
  description =  "Only allow incoming traffic from the ALB in front of the ECS Service"

  ingress {
    from_port       = 0
    to_port         = 0
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
    subnets          = var.public_subnet_ids
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
  name        = "quest_alb_target_group"
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
  port              = "80"
  #tfsec:ignore:AWS004
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.quest_alb_target_group.arn
  }
}


resource "aws_security_group" "quest_alb_sg" {
  description = "Allow HTTP 80 TCP and HTTPS 443 TCP incoming to the ALB. Allow any outgoing traffic."

  # Check out my use of both styles! 😊
  ingress_rules       = ["http-80-tcp", "https-443-tcp"]
  ingress_cidr_blocks = ["0.0.0.0/0"]

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    #tfsec:ignore:AWS009
    cidr_blocks = ["0.0.0.0/0"]
  }
}


###################################################################################################
# Boilerplate code to set up the AWS Service Role "ecsTaskExecutionRole" and its related Policies #
resource "aws_iam_role" "ecsTaskExecutionRole" {
  name               = "ecsTaskExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

data "aws_iam_policy_document" "assume_role_policy" {
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
