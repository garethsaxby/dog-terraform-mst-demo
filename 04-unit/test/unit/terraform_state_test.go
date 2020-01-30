package test

import (
	"fmt"
	"strings"
	"testing"

	awsSDK "github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/dynamodb"
	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestTerraformStateBucket(t *testing.T) {
	t.Parallel()

	// Setup Input Vars
	awsRegion := aws.GetRandomStableRegion(t, nil, nil)
	bucketName := fmt.Sprintf("terratest-state-bucket-%s", strings.ToLower(random.UniqueId()))
	tableName := fmt.Sprintf("terratest-lock-table-%s", random.UniqueId())

	// Setup Terraform
	terraformOptions := &terraform.Options{
		TerraformDir: "../../",

		Vars: map[string]interface{}{
			"lock_table_name":   tableName,
			"state_bucket_name": bucketName,
		},

		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": awsRegion,
		},
	}

	// Run terraform destroy no matter what
	defer terraform.Destroy(t, terraformOptions)

	// Init and Apply Terraform
	terraform.InitAndApply(t, terraformOptions)

	validateState(t, terraformOptions)
}

func validateState(t *testing.T, terraformOptions *terraform.Options) {
	// TODO: Don't recreate the input variables twice
	awsRegion := terraformOptions.EnvVars["AWS_DEFAULT_REGION"]
	bucketName := fmt.Sprintf("%v", terraformOptions.Vars["state_bucket_name"])
	tableName := fmt.Sprintf("%v", terraformOptions.Vars["lock_table_name"])

	// DynamoDB Test Setup
	keySchema := []*dynamodb.KeySchemaElement{
		{AttributeName: awsSDK.String("LockID"), KeyType: awsSDK.String("HASH")},
	}
	tableCmk := aws.GetCmkArn(t, awsRegion, "alias/aws/dynamodb")

	// S3 TESTS
	// Test S3 Bucket Exists
	aws.AssertS3BucketExists(t, awsRegion, bucketName)

	// Test Bucket Versioning has been enabled
	versioningStatus := aws.GetS3BucketVersioning(t, awsRegion, bucketName)
	assert.Equal(t, "Enabled", versioningStatus)

	// DYNAMODB TESTS
	// Select the DynamoDB table
	table := aws.GetDynamoDBTable(t, awsRegion, tableName)

	// Test DynamoDB table has been created
	assert.Equal(t, "ACTIVE", awsSDK.StringValue(table.TableStatus))
	// Test DynamoDB table attributes are as expected
	assert.Equal(t, keySchema, table.KeySchema)
	// Test billing billing_mode
	assert.Equal(t, "PAY_PER_REQUEST", awsSDK.StringValue(table.BillingModeSummary.BillingMode))

	// Test DynamoDB table encryption is as expected
	assert.Equal(t, tableCmk, awsSDK.StringValue(table.SSEDescription.KMSMasterKeyArn))
	assert.Equal(t, "ENABLED", awsSDK.StringValue(table.SSEDescription.Status))
	assert.Equal(t, "KMS", awsSDK.StringValue(table.SSEDescription.SSEType))
}
