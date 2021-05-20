# GitHub Action: Candidate Branch(es) from PRs

This generates a list of branches who have PRs that pass a number of criteria:
* Open PRs
* Pass all available checks
* Is "MERGEABLE" (doesn't need to be updated with the base)
* Cannot be "Draft"
* Are against the specified base bratch
* Pass the tag filters given in the options

# Environment variables
`GITHUB_TOKEN` -- Authorization token to allow access. See also: https://docs.github.com/en/actions/reference/authentication-in-a-workflow
`GITHUB_REPOSITORY` -- the name of the repository to check; provided (see https://docs.github.com/en/actions/reference/environment-variables)

# Options

| Option               | Required? | Description                                             | default  |
|----------------------|-----------|---------------------------------------------------------|----------|
| -b, --base           | N         | target branch of PRs to search for                      | `master` |
| -n, --reject-labels  | N         | Ignore any PRs with this array of tags; use "" to clear | `hold`   |
| -y, --require-labels | N         | Require PRs to have these tags                          | `ready`  |
| -d, --debug          | N         | Debug log level                                         | Warn     |
| -v, --verbose        | N         | Info log level                                          | Warn     |

## Note on options

To pass an empty array into `--reject-labels` or `--require-labels`, add `""`. e.g.

`ruby select_prs.rb -y ""` to specify no labels are required.
