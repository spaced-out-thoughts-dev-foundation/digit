# app.rb
require 'sinatra'
require 'sinatra/base'
require 'yaml'
require 'open3'

class App < Sinatra::Base
  set :bind, '0.0.0.0'

  get '/' do
    send_file 'index.html'
  end

  post '/api/compile' do
    request_body = request.body.read
    json_data = JSON.parse(request_body)

    # Access JSON data fields
    content = json_data['content']
    type = json_data['type']
    name = json_data['name']

    Dir.chdir("./bean-stock/#{type}/#{name}") do
      File.delete('temp.rs') if File.exist?('temp.rs')

      File.write('temp.rs', content)

      # If we don't do this, we have issues installing gems
      # not from the root Gemfile
      output, status = Bundler.with_original_env do
        Open3.capture2e('make run file=temp.rs')
      end

      return {
        output: output,
        status: status.exitstatus,
        message: "Received JSON data: content = #{content}, type = #{type}, name = #{name}"
      }.to_json
    end
  end

  # API endpoint to retrieve a message
  get '/api/manifests' do
    repositories = fetch_repositories('./bean-stock/frontend') + fetch_repositories('./bean-stock/backend')

    manifest_file_name = 'bean_stock_manifest.yaml'

    repositories = repositories.map do |repository_path|
      manifest_path = "#{repository_path}/#{manifest_file_name}"

      if File.exist?(manifest_path)
        loaded_manifest = YAML.load_file(manifest_path)

        manifest_version = loaded_manifest['version'].strip

        version = Dir.chdir(repository_path) do
          output, = Open3.capture2e('make version')

          Open3.capture2e('make build')

          output.strip
        end

        {
          description: loaded_manifest['description'],
          name: loaded_manifest['name'],
          type: loaded_manifest['type'],
          version: loaded_manifest['version'],
          success: manifest_version == version
        }
      else
        puts 'No manifest found'

        nil
      end
    end.compact

    {
      repositories: repositories
    }.to_json
  end

  def fetch_repositories(dir_path, _indent = '')
    return [] unless File.directory?(dir_path)

    repositories = []

    Dir.foreach(dir_path) do |entry|
      next if ['.', '..'].include?(entry)

      repositories << "#{dir_path}/#{entry}"
    end

    repositories
  end
end
