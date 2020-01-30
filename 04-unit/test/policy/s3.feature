Feature: State Storage S3 Bucket
  Scenario: Encryption enabled
    Given I have AWS S3 Bucket defined
    Then it must contain server_side_encryption_configuration

  Scenario: Versioning enabled
    Given I have AWS S3 Bucket defined
    Then it must contain versioning
    And it must contain enabled
    And its value must be true

  Scenario: Private Canned ACL set
    Given I have AWS S3 Bucket defined
    Then it must contain acl
    And its value must be private

  Scenario: Force Destroy disabled
    Given I have AWS S3 Bucket defined
    Then it must contain force_destroy
    And its value must be false