# SurveyMonkey Survey Creator

Creates a SurveyMonkey surveyfrom a JSON spec, and emails an invite to a list of recipients.

## Setup

1. Sign up at https://www.surveymonkey.com
2. Create a draft app at https://developer.surveymonkey.com
   - Under permissions, enable: `create/modify surveys`, `create/modify surveys`
3. Copy the access token from your draft app.
4. Install dependencies:
   pip install requests
5. Set your token:
   export SURVEYMONKEY_ACCESS_TOKEN=token

## Usage

python survey_script.py survey.json emails.txt

- survey.json — survey definition (format below)
- emails.txt — one recipient email per line, minimum 2 (not rly)

## JSON format

{
  "My Survey": {
    "Page 1": {
      "Q1": { "Description": "How satisfied are you?",
              "Answers": ["Yassified", "Satisfied", "Unsatisfied"] 
            }
        }
    }
}
