# app.rb
require 'sinatra'
require 'sinatra/base'
require 'yaml'
require 'open3'
require 'json'
require 'dtr_core'

require 'sinatra/cross_origin'

class App < Sinatra::Base
  configure do
    enable :cross_origin
  end

  before do
    response.headers['Access-Control-Allow-Origin'] = '*'
    response.headers['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS'
    response.headers['Access-Control-Allow-Headers'] = 'Content-Type, Authorization, Accept'
  end

  # Handle preflight OPTIONS requests
  options '*' do
    response.headers['Allow'] = 'HEAD,GET,POST,PUT,DELETE,OPTIONS'
    response.headers['Access-Control-Allow-Origin'] = '*'
    response.headers['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS'
    response.headers['Access-Control-Allow-Headers'] = 'Content-Type, Authorization, Accept'
    200
  end

  set :bind, '0.0.0.0'

  get '/' do
    send_file 'index.html'
  end

  get '/api/supported_types_and_instructions' do
    {
      supported_instructions: DTRCore::SupportedAttributes::INSTRUCTIONS,
      supported_types: DTRCore::SupportedAttributes::TYPES
    }.to_json
  end

  post '/api/compile' do
    request_body = request.body.read
    json_data = JSON.parse(request_body)

    # Access JSON data fields
    content = json_data['content']
    name_types = json_data['name_types']

    puts 'Received request'
    puts "Content: #{content}"
    puts "name_types: #{name_types}"

    outputs = []
    last_content = content

    name_types.each do |name_type|
      name = name_type['name']
      type = name_type['type']
      output_to_return = Dir.chdir("./bean-stock/#{type}/#{name}") do
        puts "Compiling #{name}"

        File.delete('temp.rs') if File.exist?('temp.rs')

        File.write('temp.rs', last_content)

        # If we don't do this, we have issues installing gems
        # not from the root Gemfile
        output, status = Bundler.with_original_env do
          Open3.capture2e('make run file=temp.rs')
        end

        puts "Output: #{output}"
        puts "Status: #{status.exitstatus}"

        output_to_return = {
          output: output,
          status: status.exitstatus,
          message: "Received JSON data: last_content = #{last_content}, type = #{type}, name = #{name}"
        }.to_json

        last_content = output

        puts "Output to return: #{output_to_return}"

        outputs << output_to_return
      end
    end

    { results: outputs }.to_json
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

          output.strip
        end

        {
          description: loaded_manifest['description'],
          name: loaded_manifest['name'],
          type: loaded_manifest['type'],
          version: loaded_manifest['version'],
          success: manifest_version == version,
          source: loaded_manifest['source']
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
