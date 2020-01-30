fmt:
	terraform fmt

validate:
	AWS_DEFAULT_REGION=eu-west-1 terraform validate

lint:
	tflint

plan:
	AWS_DEFAULT_REGION=eu-west-1 terraform plan -var-file=test/test.tfvars

compliance:
	AWS_DEFAULT_REGION=eu-west-1 terraform plan -var-file=test/test.tfvars -out=tf.plan
	terraform-compliance --features test/policy --planfile tf.plan

static: validate lint compliance

unit:
	cd test/unit; go test -v -timeout 60m

