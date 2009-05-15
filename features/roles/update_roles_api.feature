Feature: Update a User
  In order to keep my user data up-to-date
  As an individual 
  I want to update my User with Opscode

  Scenario Outline: Update a user 
    Given a 'user' named 'bobo' exists
      And changing the 'user' field '<field>' to '<updated_value>'
     When I 'PUT' the 'user' to the path '/users/bobo' 
     Then the response code should be '200' 
      And the inflated responses key '<field>' should match '^<updated_value>$'
     When I 'GET' the path '/users/bobo'
     Then the inflated responses key '<field>' should match '^<updated_value>$'

    Examples:
      | field        | updated_value |
      | first_name   | Bobolicious   |
      | middle_name  | Tiberious     |
      | last_name    | Clownerton    |
      | display_name | Bobolicious T. Clownerton  |
      | email        | bobo@clowntown.com         |

  Scenario: Update a users username
    Given a 'user' named 'bobo' exists
      And changing the 'user' field 'username' to 'bobotclown'
     When I 'PUT' the 'user' to the path '/users/bobo' 
     Then the response code should be '201' 
      And the inflated responses key 'uri' should match '^http://.+/users/bobotclown'

  Scenario Outline: Update a user with a missing required field 
    Given a 'user' named 'bobo' exists
      And removing the 'user' field '<field>'
     When I 'PUT' the 'user' to the path '/users/bobo' 
     Then the response code should be '400'
      And the inflated responses key 'error' should include '<capital_field> must not be blank'

    Examples:
      | field        | capital_field |
      | username     | Username      |
      | first_name   | First name    |
      | last_name    | Last name     |
      | display_name | Display name  |
      | email        | Email         |

  Scenario Outline: Update a user with an invalid field 
    Given an 'user' named 'bobo' exists
      And changing the 'user' field '<field>' to '<new_value>'
     When I 'PUT' the 'user' to the path '/users/bobo' 
     Then the response code should be '400'
      And the inflated responses key 'error' should include '<capital_field> has an invalid format'

    Examples:
      | field        | new_value      | capital_field |
      | username     | CHeeky CLown!! | Username      |
      | email        | bobo#ge.com    | Email         |


