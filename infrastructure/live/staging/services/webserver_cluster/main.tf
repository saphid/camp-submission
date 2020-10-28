terraform {
  backend "s3" {
    bucket = "go-webserver-demo-alxs001"
    key    = "staging/services/webserver-cluster/terraform.tfstate"
    region = "us-east-2"

    dynamodb_table = "terraform_staging_state_locks"
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
                sudo apt-get update
                sudo amazon-linux-extras install docker
                sudo docker pull saphid/go-webserver-demo:0.3
                sudo docker run -d -p 80:8080 saphid/go-webserver-demo:0.3 -e "TABLE_NAME=${aws_dynamodb_table.webserver_table.name}"
                EOF

  cluster_name = "staging"
  instance_type = "t2.micro"
  min_size = 2
  max_size = 2
}
