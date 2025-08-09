# check-commit-messages

GitHub Action to validate commits messages in pull requests
Checks if commits contans a specific keyword.
By default if **atleast one commit** contains the keyword the actions passes.
There is an option to require all commits to contain the keyword.

## Usage

An example on how to use this action in your workflows can be found under.

```yaml
name: check commit messages

on:
  pull_request:
    branches: [master]

jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Run commit message check
        uses: BetaTH13/check-commit-messages@1.0.0
        with:
          keyword: "JIRA-"
          # optional defaults to false
          require-all: "true"
```

## Inputs

| Name | Required | Description
|keyword | Yes | The keyword which needs to be contained in the commit message
|require-all| No | When **"false"** only 1 commit needs to containt the commit message. When **"true"** all commit messages must contain the keyword

## Issues

Feel free to open issues in case of bugs or if you want to request for a new feature
