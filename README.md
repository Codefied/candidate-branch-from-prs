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

| Option               | Required? | Description                                             | default  |
|----------------------|-----------|---------------------------------------------------------|----------|
| -b, --base           | N         | target branch of PRs to search for                      | `master` |
| -n, --reject-labels  | N         | Ignore any PRs with this array of tags; use "" to clear | `hold`   |
| -y, --require-labels | N         | Require PRs to have these tags                          | `ready`  |
| -1, --at-least-one-label | N     | At least one of these tags is required                  | `[]`     |
| -d, --debug          | N         | Debug log level                                         | Warn     |
| -v, --verbose        | N         | Info log level                                          | Warn     |

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
