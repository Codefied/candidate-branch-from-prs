# frozen_string_literal: true

require 'graphql/client'
require 'graphql/client/http'
require 'logger'

# Module to do our GraphQL queries off of GitHub and PR filtering
module GitHub
  HTTP = GraphQL::Client::HTTP.new('https://api.github.com/graphql') do
    def headers(_context)
      raise 'Missing GitHub Access Token' unless (token = ENV['GITHUB_ACCESS_TOKEN'])

      {
        'Authorization' => "Bearer #{token}"
      }
    end
  end

  Schema = GraphQL::Client.load_schema(HTTP)

  Client = GraphQL::Client.new(
    schema: Schema,
    execute: HTTP
  )

  PR_QUERY_TEMPLATE = <<~'GRAPHQL'
    {
      repository(owner: "Codefied", name: "housecall-web") {
        pullRequests(first: 100, %s states: OPEN, orderBy: {direction: ASC, field: UPDATED_AT}) {
          pageInfo {
            endCursor
            hasNextPage
          }
          edges {
            node {
              isDraft
              mergeable
              updatedAt
              baseRefName
              headRef {
                prefix
                name
                target {
                  oid
                }
              }
              labels(first: 100) {
                edges {
                  node {
                    name
                  }
                }
              }
              commits(last: 1) {
                nodes {
                  commit {
                    commitUrl
                    oid
                    status {
                      state
                    }
                  }
                }
              }

            }
          }
        }
      }
    }
  GRAPHQL

  FirstQuery = Client.parse(PR_QUERY_TEMPLATE % '')
  NextQuery  = Client.parse("query($cursor: String!) #{PR_QUERY_TEMPLATE % 'after: $cursor,'}")

  def self.pr_filter(graphql_result, base, reject_labels, required_labels)
    filtered_pr_refs = []
    graphql_result.data.repository.pull_requests.edges.each do |pr|
      next if pr.node.is_draft?
      next if pr.node.mergeable != 'MERGEABLE'
      next if pr.node.commits.nodes[0].commit.status.state != 'SUCCESS'
      next if pr.node.base_ref_name != base

      labels = pr.node.labels.edges.map { |e| e.node.name }.compact
      next if !reject_labels.empty? && (labels & reject_labels != [])
      next if !required_labels.empty? && ((labels & required_labels).sort != required_labels.sort)

      $logger.debug("Appending #{pr.node.head_ref.name}")
      filtered_pr_refs.append(pr.node.head_ref.name)
    end
    filtered_pr_refs
  end

  def self.branches_matching_filter(base: 'master', reject_labels: ['hold'], required_labels: ['ready'])
    result = GitHub::Client.query(GitHub::FirstQuery)
    good_prs = GitHub.pr_filter(result, base, reject_labels, required_labels)
    while result.data.repository.pull_requests.page_info.has_next_page?
      cursor = result.data.repository.pull_requests.page_info.end_cursor
      $logger.debug("Next Page: #{cursor}")
      result = GitHub::Client.query(GitHub::NextQuery, variables: { cursor: cursor })
      good_prs += GitHub.pr_filter(result, base, reject_labels, required_labels)
    end
    good_prs
  end
end

$logger = Logger.new(STDOUT)
