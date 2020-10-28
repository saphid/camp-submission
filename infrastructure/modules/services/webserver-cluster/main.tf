
terraform {
  backend "s3" {
    bucket = "go-webserver-demo-alxs001"
    key    = "${var.cluster_name}/services/webserver-cluster/terraform.tfstate"
    region = "us-east-2"

    dynamodb_table = "terraform_state_locks"
    encrypt        = true
  }
}

variable "server_port" {
  type    = number
  default = 8080
}

variable "key_name" {
  type    = string
  default = "tf_study"
}

data "aws_availability_zones" "all" {}

resource "aws_security_group" "clb" {
  name = "${var.cluster_name}-web-clb"

  # From inside AWS to the CLB
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # From the internet to the CLB
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "webserver" {
  name = "${var.cluster_name}-web-instance"

  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ssh" {
  name = "${var.cluster_name}-ssh-instance"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_elb" "web_clb" {
  name               = "${var.cluster_name}-web-clb"
  security_groups    = [aws_security_group.clb.id]
  availability_zones = data.aws_availability_zones.all.names

  health_check {
    target              = "HTTP:${var.server_port}/"
    interval            = 30
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  listener {
    lb_port           = 80
    lb_protocol       = "http"
    instance_port     = var.server_port
    instance_protocol = "http"
  }
}

resource "aws_launch_configuration" "webserver" {
  image_id        = "ami-0c55b159cbfafe1f0"
  instance_type   = var.instance_type
  security_groups = [aws_security_group.webserver.id, aws_security_group.ssh.id]
  key_name        = var.key_name

  user_data = var.user_data

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "web_asg" {
  launch_configuration = aws_launch_configuration.webserver.id
  availability_zones   = data.aws_availability_zones.all.names

  min_size = var.min_size
  max_size = var.max_size

  load_balancers    = [aws_elb.web_clb.name]
  health_check_type = "ELB"

  tag {
    key                 = "Name"
    value               = "${var.cluster_name}-webserver"
    propagate_at_launch = true
  }
}
