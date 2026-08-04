#!/usr/bin/env python3

import argparse
import json
import os
import requests

BASE_URL = "https://api.surveymonkey.com/v3"

def getHeaders(access_token):
    return {
        "Authorization": f"Bearer {access_token}",
        "Content-Type": "application/json",
        "Accept": "application/json",
    }

def loadSurveyJson(path):
    with open(path, "r") as f:
        return json.load(f)


def loadEmails(path):
    with open(path, "r") as f:
        emals = [line.strip() for line in f if line.strip()]
    return emals

def createSurvey(headers, title):
    response = requests.post(
        f"{BASE_URL}/surveys",
        headers=headers,
        json={"title": title},
    )
    if not response.ok:
        print(response.status_code, response.text)
    response.raise_for_status()
    return response.json()["id"]


def createPage(headers, survey_id, title):
    response = requests.post(
        f"{BASE_URL}/surveys/{survey_id}/pages",
        headers=headers,
        json={"title": title},
    )
    response.raise_for_status()
    return response.json()["id"]

def createQuestion(headers, survey_id, page_id, question_text, description, answers):
    body = {
        "headings": [{"heading": question_text}],
        "family": "single_choice",
        "subtype": "vertical",
        "answers": {
            "choices": [{"text": answer} for answer in answers]
        },
    }
    response = requests.post(
        f"{BASE_URL}/surveys/{survey_id}/pages/{page_id}/questions",
        headers=headers,
        json=body,
    )
    response.raise_for_status()
    return response.json()["id"]


def createCollector(headers, survey_id, name):
    response = requests.post(
        f"{BASE_URL}/surveys/{survey_id}/collectors",
        headers=headers,
        json={"type": "weblink", "name": name},
    )
    if not response.ok:
        print(response.status_code, response.text)
    response.raise_for_status()
    return response.json()["id"]

def createMessage(headers, collector_id, subject, body_text):
    response = requests.post(
        f"{BASE_URL}/collectors/{collector_id}/messages",
        headers=headers,
        json={"type": "invite", "subject": subject, "body": body_text},
    )
    response.raise_for_status()
    return response.json()["id"]


def addRecipients(headers, collector_id, message_id, emails):
    contacts = [{"email": email} for email in emails]
    response = requests.post(
        f"{BASE_URL}/collectors/{collector_id}/messages/{message_id}/recipients/bulk",
        headers=headers,
        json={"contacts": contacts},
    )
    response.raise_for_status()


def sendMessage(headers, collector_id, message_id):
    response = requests.post(
        f"{BASE_URL}/collectors/{collector_id}/messages/{message_id}/send",
        headers=headers,
        json={},
    )
    response.raise_for_status()

def buildSurvey(headers, survey_data):
    survey_name = list(survey_data.keys())[0]
    pages_data = survey_data[survey_name]

    survey_id = createSurvey(headers, survey_name)
    print(f"Created survey '{survey_name}' -> {survey_id}")

    for page_name, questions_data in pages_data.items():
        page_id = createPage(headers, survey_id, page_name)
        print(f"Created page '{page_name}' -> {page_id}")

        for question_name, question_info in questions_data.items():
            description = question_info["Description"]
            answers = question_info["Answers"]

            question_id = createQuestion(
                headers, survey_id, page_id, description, description, answers
            )
            print(f"    Created question '{question_name}' -> {question_id}")

    return survey_id

def main():
    parser = argparse.ArgumentParser(description="Creating a survey from json ")
    parser.add_argument("survey_json", type=str, help="Path to the JSON file with survey questions")
    parser.add_argument("emails", type=str, help="Path to a text file with recipient emails, one per line")
    parser.add_argument("--access-token", type=str, default=os.environ.get("SURVEYMONKEY_ACCESS_TOKEN"), help="SurveyMonkey access token (or set SURVEYMONKEY_ACCESS_TOKEN env var)")
    args = parser.parse_args()

    if not args.access_token:
        parser.error(f"access token not passed")

    headers = getHeaders(args.access_token)
    survey_data = loadSurveyJson(args.survey_json)
    emails = loadEmails(args.emails)

    if len(emails) < 2:
        raise ValueError(f"You can't put less than two emails.")

    survey_id = buildSurvey(headers, survey_data)

    collector_id = createCollector(headers, survey_id, "Assignment Collector")
    print(f"Created collector -> {collector_id}")

    # message_id = createMessage(
    #     headers, collector_id,
    #     subject="plz complete my survey",
    #     body_text="i need to complete the survey asap",
    # )
    # print(f"Created message -> {message_id}")
    #
    # addRecipients(headers, collector_id, message_id, emails)
    # print(f"Added {len(emails)} recipients")
    #
    # sendMessage(headers, collector_id, message_id)
    # print("survey sent")

    print("Survey created successfully.")

main()