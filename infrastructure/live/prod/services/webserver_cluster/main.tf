terraform {
  backend "s3" {
    bucket = "go-webserver-demo-alxs001"
    key    = "prod/services/webserver-cluster/terraform.tfstate"
    region = "us-east-2"

    dynamodb_table = "terraform_prod_state_locks"
    encrypt        = true
  }
}


provider "aws" {
  region = "us-east-2"
}

resource "aws_dynamodb_table" "webserver_table" {
  name         = "webserver_table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "Title"

  attribute {
    name = "Title"
    type = "S"
  }
}


module "webserver_cluster" {
  source = "../../../../modules/services/webserver-cluster"

  user_data = <<-EOF
                #!/bin/bash
                curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
                sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
                sudo apt-get update
                apt-cache policy docker-ce
                sudo apt-get install -y docker-ce
                sudo docker pull saphid/go-webserver-demo:0.3
                sudo docker run -d -p 80:8080 saphid/go-webserver-demo:0.3 -e "TABLE_NAME=${aws_dynamodb_table.webserver_table.name}"
                EOF

  cluster_name = "prod"
  instance_type = "t2.micro"
  min_size = 2
  max_size = 10
}

resource "aws_autoscaling_schedule" "scale_out_business_hours" {
  scheduled_action_name = "scale-out-during-business-hours"
  min_size = 2
  max_size = 10
  desired_capacity = 10
  recurrence = "0 9 * * *"

  autoscaling_group_name = module.webserver_cluster.asg_name
}

resource "aws_autoscaling_schedule" "scale_in_at_night" {
  scheduled_action_name = "scale-in-at-night"
  min_size = 2
  max_size = 10
  desired_capacity = 2
  recurrence = "0 17 * * *"

  autoscaling_group_name = module.webserver_cluster.asg_name
}