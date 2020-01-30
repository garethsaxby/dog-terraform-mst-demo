Feature: State Lock DynamoDB Table
  Scenario: Pay Per Request enabled
    Given I have aws_dynamodb_table defined
    Then it must contain billing_mode
    And its value must be PAY_PER_REQUEST

  Scenario: Server Side Encrpytion Enabled
    Given I have aws_dynamodb_table defined
    Then it must contain server_side_encryption
    And it must contain enabled
    And its value must be true

  Scenario: Point in time Recovery Disabled
    Given I have aws_dynamodb_table defined
    When it contains point_in_time_recovery
    And it contains enabled
    And its value must not be true

  Scenario: Hash Key is set correctly
    Given I have aws_dynamodb_table defined
    Then it must contain hash_key
    And its value must be "LockID"
