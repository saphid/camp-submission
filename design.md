# Design doc: Deploy Golang webapp to AWS

## Background
Given some golang code, we are going to create infrastructure as code to deploy that golang webserver to AWS. This is a project with a short delivery time but still should be production ready. 

## Definitions

|| 	|
|---|---|
|IAC|Infrastructure As Code|
|terraform|https://www.terraform.io/|
|AWS| Amazon Web Services|
|EC2| Elastic Cloud Compute|
|ASG| Auto Scaling Groups|
|userdata| Code that runs at boot on an EC2 instance|
|Launch configurations| Used by ASG to launch EC2 instances
|Cloudwatch| AWS logging and reporting tools|


## Goals

This project will use EC2 to deploy the web server. We will be downloading the current version of the golang code to the EC2 instance on boot as part of the userdata.
We will be using terraform to create Launch configs for the golang webservers.
These server will have logging and metric in cloudwatch

## Non-Goals

We will not be making this mutli-region, and will not be setting up a deploy environment like "blue/green". They will be left for a later date.

## Open questions

* What do I need to make golang run
* How do I enable cloud watch

## Design

### Proposal

This document proposes deploying the provided golang webserver to AWS using terraform. 

This is a fairly straightfoward project that involves only a few components.

* AWS setup
* Terraform setup
* Launch Configurations
* Autoscaling groups
* Security Groups
* Elastic Load Balancers

#### AWS setup

Before we can deploy anything to AWS we will assume that there is already an AWS account. This project will need a new user with the below roles assigned to it.

* AmazonRDSFullAccess
* AmazonEC2FullAccess
* IAMFullAccess
* AmazonS3FullAccess
* CloudWatchFullAccess
* AmazonDynamoDBFullAccess

Next we need to have the access and secret access keys in your local env.

``export AWS_SECRET_ACCESS_KEY=XXXXXXXXXXXXXXXXXXXXXXXXXXXXX``
``export AWS_ACCESS_KEY_ID=XXXXXXXXXXXXXXXXXXXXXXXXXX``

#### Terraform setup

To make sure that this deploy can be scalable we will setup a terraform backend. There will be a seperate terraform file that will deploy S3 bucket and DynamoDB Table for state storage and deploy locking.

Once these have been deployed they will be used for the rest of the terraform files by specifying the terraform backend in each terraform file.

#### Launch Configuration

We will be using a base ubuntu image for now as it includes much of the utilities we want and is an industry standard.

For the current scale of this project will we be deploying to "t2.micro" for the demonstration prototype of this project and will revisit the needs of the webserver as it's code becomes more resource intensive

To start will we require a minimum of two hosts and a maximum of 10, this will allow scaling with demand and a base level of redundancy.

#### Auto Scaling Group

ASG are the obvious choice for this sort of deployment strategy.

#### Security groups

We will allow traffic from any external source to the load balances and will allow any traffic from the load balancers to EC2

#### Elastic Load Balancers

While classic load balancers are easiest to deploy we will investigate the use of application load balancers as they have more ongoing support and more features to allow for future expansion