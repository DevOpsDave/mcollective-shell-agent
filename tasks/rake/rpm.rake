require File.expand_path('../../env', __FILE__)

require 'yaml'

$:.unshift(File.join(File.dirname(__FILE__), 'lib', 'packaging'))
require 'rpm_packager'

base_directory = File.join(File.dirname(__FILE__), '..', '..')

desc "Prepare build environment"
task :prepare_build_environment do
  puts "Setting up the build environment"

  FileUtils.mkpath("#{RESULTS}/dist")
  FileUtils.mkpath("#{RESULTS}/input")
end

desc "Build mcollective common RPM"
task :build_mcollective_common_rpm do
  plugin_name = "mcollective-shell-common"

  puts "Setting up build environment..."
  FileUtils.mkpath("#{RESULTS}/input/#{plugin_name}/usr/libexec/mcollective/mcollective/agent")

  FileUtils.copy("#{base_directory}/agent/shell.ddl", "#{RESULTS}/input/#{plugin_name}/usr/libexec/mcollective/mcollective/agent")

  puts "Building #{plugin_name} RPM..."
  rpm_packager = RpmPackager.new
  output = rpm_packager.build(plugin_name, {"mcollective-common" => "#{ENV['mcollective-common-version']}"})
  puts output
end

desc "Build mcollective agent RPM"
task :build_mcollective_agent_rpm do
  plugin_name = "mcollective-shell-agent"

  puts "Setting up build environment..."
  FileUtils.mkpath("#{RESULTS}/input/#{plugin_name}/usr/libexec/mcollective/mcollective/agent")

  FileUtils.copy("#{base_directory}/agent/shell.rb", "#{RESULTS}/input/#{plugin_name}/usr/libexec/mcollective/mcollective/agent")

  version = YAML.load_file("#{RESULTS}/dist/mcollective-shell-common.yaml")['version']

  puts "Building #{plugin_name} RPM..."
  rpm_packager = RpmPackager.new
  output = rpm_packager.build(plugin_name, {"mcollective-shell-common" => "#{version}", "mcollective-common" => "#{ENV['mcollective-common-version']}"})
  puts output
end

desc "Build mcollective client RPM"
task :build_mcollective_client_rpm do
  plugin_name = "mcollective-shell-client"

  puts "Setting up build environment..."
  FileUtils.mkpath("#{RESULTS}/input/#{plugin_name}/usr/libexec/mcollective/mcollective/application")

  FileUtils.copy("#{base_directory}/application/shell.rb", "#{RESULTS}/input/#{plugin_name}/usr/libexec/mcollective/mcollective/application")

  version = YAML.load_file("#{RESULTS}/dist/mcollective-shell-common.yaml")['version']

  puts "Building #{plugin_name} RPM..."
  rpm_packager = RpmPackager.new
  output = rpm_packager.build(plugin_name, {"mcollective-shell-common" => "#{version}", "mcollective-common" => "#{ENV['mcollective-common-version']}"})
  puts output
end
