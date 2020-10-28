# Getting setup

## Add your environment keys

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

## Install terraform and get started

* Install terraform on your local system.
* Browse to the ./setup folder
* You will need to update the name of the s3 bucket to something unique
* Run terraform init
* Run terraform apply

This will create the terraform backend for the rest of the project.

## Deploying the environment

Browse to which ever environment you want to deploy for now we'll start with staging.

* Browse to ./infrastructure/live/staging/services/webserver_cluster
* Update the terraform backend s3 bucket name in main.tf
* Run terraform init
* Run terraform apply

## Have fun

If everything is working then you should be able to browse to the url output at the end of the terraform apply process and see the deployed page.


## Updating the code

Code is deployed with docker. Check out the code/webserver folder. Update your go code. 

* Run docker build --tag goweb:<version number> .
* Run docker docker --tag goweb:<version number> saphid/go-webserver-demo:<version number> (If you want to do this you'll need to use your own repo)
* Run docker push saphid/go-webserver-demo:<version number>
 
