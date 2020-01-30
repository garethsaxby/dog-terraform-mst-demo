Feature: Consistent Tagging
  Scenario Outline: Ensure that specific tags are defined
    Given I have resource that supports tags defined
    Then it must contain tags
    And it must contain <tags>
    And its value must not be null

    Examples:
      | tags    |
      | Name    |
      | Purpose |
