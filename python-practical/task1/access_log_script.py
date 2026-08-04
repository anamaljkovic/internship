#!/usr/bin/env python3

import argparse
import re

LOG_PATTERN = re.compile(
    r'^(?P<ip>\S+) \S+ \S+ \[(?P<timestamp>[^\]]+)\] '
    r'"(?P<method>\S+) (?P<endpoint>\S+) (?P<http_version>[^"]+)" '
    r'(?P<response_code>\d+) (?P<response_time>\S+) '
    r'"(?P<referrer>[^"]*)" "(?P<user_agent>[^"]*)"$'
)

def parseLog(filename: str):
    user_agents = {}
    with open(filename, "r") as f:
        for line_number, line in enumerate(f, start=1):
            line = line.strip()

            if not line:
                continue

            match = LOG_PATTERN.match(line)
            if not match:
                print(f"error at line number {line_number}")
                continue
            user_agent = match.group("user_agent")
            user_agents[user_agent] = user_agents.get(user_agent, 0) + 1

    return user_agents


def main():
    parser = argparse.ArgumentParser(description="User Agents in an access log statistics")
    parser.add_argument("file", type=str, help="log filename")
    args = parser.parse_args()

    user_agents = parseLog(args.file)

    print(f"there are {len(user_agents)} unique agents in this log file")

    for agent,count in user_agents.items():
        print(f"user agent {agent} -> {count}")

main()



