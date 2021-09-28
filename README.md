# GitHub Action: Candidate Branch(es) from PRs

This generates a list of branches who have PRs that pass a number of criteria:
* Open PRs
* Pass all available checks
* Is "MERGEABLE" (doesn't need to be updated with the base)
* Cannot be "Draft"
* Are against the specified base bratch
* Pass the tag filters given in the options

**See .github/workflows/main.yml for an example invocation**

# Environment variables

`GITHUB_TOKEN` -- Authorization token to allow access. See also: https://docs.github.com/en/actions/reference/authentication-in-a-workflow

`GITHUB_REPOSITORY` -- the name of the repository to check; provided (see https://docs.github.com/en/actions/reference/environment-variables)

# Options

| Required? | Option                   | Description                                                         | default        |
|-----------|--------------------------|---------------------------------------------------------------------|----------------|
| N         | -b, --base               | target branch of PRs to search for                                  | `master`       |
| N         | -n, --reject-labels      | Ignore any PRs with this array of tags; use "" to clear             | `hold`         |
| N         | -y, --require-labels     | Require PRs to have these tags                                      | `ready`        |
| N         | -1, --at-least-one-label | At least one of these tags is required                              | `[]`           |
| N         | -u, --unknown-threshold  | Number expressing a percent of UNKNOWN state PRs to trigger a retry | `10` [percent] |
| N         | -r, --retry-delay        | Time in seconds before retrying when UNKNOWN PRs exceed threshold   | `30` (seconds) |
| N         | -m, --max-retries        | Maximum number of retries before we give up completely              | `10`           |
| N         | -d, --debug              | Debug log level                                                     | Warn           |
| N         | -v, --verbose            | Info log level                                                      | Warn           |


## Note on options

To pass an empty array into `--reject-labels` or `--require-labels`, add `""`. e.g.

`ruby select_prs.rb -y ""` to specify no labels are required.

# Legal mumbo-jumbo

    Copyright (C) 2021 Codefied, Inc. dba Housecall Pro
	  devops@housecallpro.com

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Lesser General Public
    License as published by the Free Software Foundation; either
    version 2.1 of the License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public
    License along with this library; if not, write to the Free Software
    Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301
    USA
