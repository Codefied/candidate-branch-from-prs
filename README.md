# GitHub Action: Candidate Branch from PRs

This generates a new branch from a list of the repository's PRs.

PRs must:
* Pass all available checks
* Not be "Draft"

A branch is created, and then a PR is generated from that branch. It is not auto-deployed to QA, yet.

# Options

| Option        | Required? | Description                                                           |
|---------------|-----------|-----------------------------------------------------------------------|
| branch-prefix | Y         | Prefix for the branch name to be created                              |
| pr-base       | N         | target branch of PRs to search for (if not specified, `main` is used. |
| ignore-tags   | N         | Ignore any PRs with this array of tags (e.g. `hold`, `dependency`)    |
| require-tags  | N         | Require PRs to have these tags (e.g. `ready`)                         |

