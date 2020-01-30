# AWS Terraform State Bootstrap

This is a Terraform module for bootstrapping Terraform state storage on AWS.

It creates AWS resources including an S3 bucket and DynamoDB table for storing 
Terraform state data on AWS for use within a distributed Terraform environment.

Once the AWS resources are created, a `state.ini` file is generated to use as a 
[partial configuration file](https://www.terraform.io/docs/backends/config.html#partial-configuration) 
to configure usage of the Terraform S3 state backend.


## Usage

### Deploying the Module
See the [example sub-folder](example/) for an example of how to use this module.

### Using the created Terraform State Backend
The Terraform module creates a `state.ini` file, as mentioned previously.

This can be used to configure Terraform to use the created state storage without 
having to hard code the state configuration in Terraform itself, allowing for 
code portability.

You only need to add the following to your Terraform configuration:

```
terraform {
  backend "s3" {
    # Set the key path appropriately for the state being used
    key = "category/state_name.tfstate"
  }
}
```

And then pass the location of the `state.ini` file when you initalise the 
Terraform backend:

```
terraform init -backend-config=./path/to/state.ini
```


### Where do we store the Terraform State for the creation of the Terraform state storage?

It is advised to store the state file for creating the state storage inside 
_the git repository that contains the Terraform invoking the module_.

You should _also commit the created `state.ini` file into git_.

By using git, we can still centralise and version control the state storage, and 
as you should ultimately be touching the Terraform state storage minimally, it 
is advised that anyone doing so should be experienced and disciplined enough to 
commit the updated state back to the git repository once their change is 
complete.

Do not be tempted to push the Terraform state into the backend it manages; if 
you make a mistake in a change, __you may not be able to rectify it via 
Terraform itself__ and you are creating a "chicken and egg" situation with a 
circular dependency where the state storage is dependent upon itself.


## Design Decisions

Terraform, when used by multiple users, requires a shared state backend to 
ensure all users see the same stored state, and also the capability to lock the 
state to prevent multiple users from trying to make changes at the same time.

Whilst Terraform Enterprise/Cloud is the desirable current solution for the most 
low maintenance approach, a lot of organisations want to manage their own state 
storage for security and compliance purposes, which is where this module should 
be used to store the Terraform State in the client's own AWS account to keep it 
within their own control.

### Locking

Unlike some other backends, the [S3 backend](https://www.terraform.io/docs/backends/types/s3.html) 
only supports locking with an additional resource in the form of a DynamoDB 
table.

Due to the importance of locking, this module both mandates and creates a 
DynamoDB table with no option to disable, as removing locking can lead to state 
corruption and DynamoDB has a persistent free tier making usage of the table 
trivial.

### Security and Access Control

State should only be interacted with by automation services such as CI/CD 
tooling, with a potential break glass exception, to ensure that workflows are 
neither sidestepped nor broken by manual interruption.

KMS CMKs are _not_ created by this module as they have a potentially significant 
cost associated due to historic key material, and different use cases have 
different security requirements, and so they should be created separately to the 
module and passed in as a variable instead to meet those requirements.

Regardless, encryption of both state and the lock table is enabled by default as 
part of security best practices.
