# frozen_string_literal: true

# select_prs.rb -- main action code

# Copyright (C) 2021  Codefied, Inc dba Housecall Pro
#   devops@housecallpro.com

# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.

# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.

# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301
# USA

require 'graphql/client'
require 'graphql/client/http'
require 'logger'
require 'slop'

# Module to do our GraphQL queries off of GitHub and PR filtering
module GitHub
  HTTP = GraphQL::Client::HTTP.new('https://api.github.com/graphql') do
    def headers(_context)
      raise 'Missing GitHub Access Token' unless (token = ENV['GITHUB_TOKEN'])

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

  OWNER, REPO = ENV['GITHUB_REPOSITORY'].split('/')

  PR_QUERY_TEMPLATE = <<~GRAPHQL
    {
      repository(owner: "#{self::OWNER}", name: "#{self::REPO}") {
        pullRequests(first: 100, %s states: OPEN, orderBy: {direction: ASC, field: UPDATED_AT}) {
          pageInfo {
            endCursor
            hasNextPage
          }
          edges {
            node {
              title
              author {
                login
              }
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

  @@logger = Logger.new($stdout)

  def self.log_level(level)
    @@logger.level = level
  end
  
  def self.logger
    @@logger
  end

  FirstQuery = Client.parse(PR_QUERY_TEMPLATE % '')
  NextQuery  = Client.parse("query($cursor: String!) #{PR_QUERY_TEMPLATE % 'after: $cursor,'}")

  def self.pr_filter(graphql_result, base, reject_labels, require_labels)
    filtered_pr_refs = []
    graphql_result.data.repository.pull_requests.edges.each do |pr|
      @@logger.debug("Investigating #{pr.node.title} by #{pr.node.author.login}")
      next if     GitHub.pr_is_draft?(pr)
      next unless GitHub.pr_is_mergeable?(pr)
      next unless GitHub.pr_passed_tests?(pr)
      next unless GitHub.pr_against_base?(pr, base)

      labels = pr.node.labels.edges.map { |e| e.node.name }.compact
      next if     GitHub.pr_has_rejected_labels?(pr, labels, reject_labels)
      next unless GitHub.pr_has_all_required_labels?(pr, labels, require_labels)

      @@logger.info("Appending #{pr.node.head_ref.name}")
      filtered_pr_refs.append(pr.node.head_ref.name)
    end
    filtered_pr_refs
  end

  def self.pr_is_draft?(pull_request)
    if pull_request.node.is_draft?
      @@logger.info("-- Rejecting #{pull_request.node.head_ref.name}: PR is draft.")
      return true
    end
    false
  end

  def self.pr_is_mergeable?(pull_request)
    if pull_request.node.mergeable != 'MERGEABLE'
      @@logger.info("-- Rejecting #{pull_request.node.head_ref.name}: PR merge state is #{pull_request.node.mergeable}, not MERGEABLE.")
      return false
    end
    true
  end

  def self.pr_passed_tests?(pull_request)
    if pull_request.node.commits.nodes[0].commit.status.nil?
      @@logger.debug("++ Accepting #{pull_request.node.head_ref.name} despite lack of commit status")
      return true
    end
    if pull_request.node.commits.nodes[0].commit.status.state != 'SUCCESS'
      @@logger.info("-- Rejecting #{pull_request.node.head_ref.name}: ")
      @@logger.info("   commit #{pull_request.node.commits.nodes[0].commit.oid} test state is #{pull_request.node.commits.nodes[0].commit.status.state}")
      return false
    end
    true
  end

  def self.pr_against_base?(pull_request, base)
    if pull_request.node.base_ref_name != base
      @@logger.info("-- Rejecting #{pull_request.node.head_ref.name}: PR's base #{pull_request.node.base_ref_name} is not #{base}")
      return false
    end
    true
  end

  def self.pr_has_rejected_labels?(pull_request, pr_labels, reject_labels)
    if !reject_labels.empty? && (pr_labels & reject_labels != [])
      @@logger.info("-- Rejecting #{pull_request.node.head_ref.name}: has a rejected label")
      @@logger.info("   PR Labels: #{pr_labels.join(', ')}")
      @@logger.info("   Reject labels: #{reject_labels.join(', ')}")
      return true
    end
    false
  end

  def self.pr_has_all_required_labels?(pull_request, pr_labels, require_labels)
    if !require_labels.empty? && ((pr_labels & require_labels).sort != require_labels.sort)
      @@logger.info("-- Rejecting #{pull_request.node.head_ref.name}: lacks a required label")
      @@logger.info("   PR Labels: #{pr_labels.join(', ')}")
      @@logger.info("   Required labels: #{require_labels.join(', ')}")
      return false
    end
    true
  end

  def self.branches_matching_filter(base, reject_labels, require_labels)
    result = GitHub::Client.query(GitHub::FirstQuery)
    good_prs = GitHub.pr_filter(result, base, reject_labels, require_labels)
    while result.data.repository.pull_requests.page_info.has_next_page?
      cursor = result.data.repository.pull_requests.page_info.end_cursor
      @@logger.debug("Next Page: #{cursor}")
      result = GitHub::Client.query(GitHub::NextQuery, variables: { cursor: cursor })
      good_prs += GitHub.pr_filter(result, base, reject_labels, require_labels)
    end
    good_prs
  end
end

opts = Slop.parse do |o|
  o.string '-b', '--base', 'Base branch PRs are compared against; default is master', default: 'master'
  o.array '-y', '--require-labels', 'Labels required to be in the PR. (default [\'ready\'])', default: ['ready']
  o.array '-n', '--reject-labels', 'Labels that rule out a PR (default [\'hold\'])', default: ['hold']
  o.on '-h', '--help' do
    puts o
    exit
  end
  o.bool '-d', '--debug', 'Debug-level logging.'
  o.bool '-v', '--verbose', 'Verbose logging. [INFO]'
end

GitHub.log_level(
  if opts.debug?
    Logger::DEBUG
  elsif opts.verbose?
    Logger::INFO
  else
    Logger::WARN
  end
)

GitHub.logger.debug("Github Repository: #{ENV['GITHUB_REPOSITORY']}")

branches = GitHub.branches_matching_filter(opts[:base], opts[:reject_labels], opts[:require_labels]).join(' ')
puts "::set-output name=branches::#{branches}"
