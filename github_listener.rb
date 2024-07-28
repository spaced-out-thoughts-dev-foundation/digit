require 'octokit'
require 'toml-rb'

class GithubListener
  def initialize(token, config_path: 'github_listener_config.toml')
    @client = client = Octokit::Client.new(access_token: token)
    @config = TomlRB::Parser.new(File.read(config_path)).hash
    @last_check = nil
  end

  def user
    @client.user
  end

  def repo_names
    @config['repositories']['names']
  end

  def issues_for_each_repo
    @config['repositories']['names'].each do |repo|
      @client.issues(repo).each do |issue|
        puts "##{issue.number} - #{issue.title}"
        puts "[Github Oracle]: { name: #{name}, type: #{type}, status: #{status}, output: #{output} }"
      end
    end
  end

  def start
    loop do
      now = Time.now
      puts "[Github Oracle]: { time: #{now}, stage: Fetch, status: Ok }"
      @last_check = now
    rescue StandardError => e
      puts "[Github Oracle]: { time: #{now}, status: Error, output: #{e.message} }"
    ensure
      sleep(30)
    end
  end
end
