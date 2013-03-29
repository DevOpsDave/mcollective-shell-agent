gem 'fpm', '<=0.3.11'
require 'fpm'
require 'fpm/program'
require 'pp'

$:.unshift(File.join(File.dirname(__FILE__), '..'))
require 'version_helper'

class BasePackager

  def initialize(package_type)
    self.validate_environment

    version_helper = VersionHelper.new

    @basedirectory = ENV['WORKSPACE']
    @semver_version = version_helper.semver_version
    @release = "1"
    @package_type = package_type

    case package_type
    when "rpm"
      @first_delimiter, @second_delimiter, @architecture = "-", ".", "noarch"
    when "deb"
      @first_delimiter, @second_delimiter, @architecture = "_", "_", "all"
    end
  end

  def validate_environment()
    if ENV['WORKSPACE'].nil?
      fail("Environment variable WORKSPACE has not been set.")
    end
    if ENV['BUILD_NUMBER'].nil?
      ENV["BUILD_NUMBER"] = "0"
    end
    if ENV['GIT_COMMIT'].nil?
      ENV['GIT_COMMIT'] = "54b0c58c7ce9f2a8b551351102ee0938"[0,10]
    end
  end

  def build(plugin_name, plugin_dependencies={})
    package_name = "#{plugin_name}"
    destination_file = "#{package_name}#{@first_delimiter}#{@semver_version}-#{@release}#{@second_delimiter}#{@architecture}.#{@package_type}"
    destination_folder = "#{@basedirectory}/#{RESULTS}/dist"
    description = "MCollective Plugin #{plugin_name} by Cegeka\n"

    static_arguments = ["-t", @package_type, "-s", "dir", "-a", @architecture, "-m", "Cegeka <computing@cegeka.be>"]
    exclude_arguments = ["-x", ".git", "-x", ".gitignore", "-x", "tasks", "-x", "Rakefile", "-x", "target", "-x", "README.md"]
    var_arguments = ["-n", package_name, "-v", @semver_version, "--iteration", @release, "--description", description, "-C", "#{@basedirectory}/#{RESULTS}/input/#{plugin_name}", "usr"]
    dependency_arguments = []
    plugin_dependencies.each { |dependent_package,dependent_version|
      dependency_arguments << "-d"
      if dependent_version.empty?
        dependency_arguments << "#{dependent_package}"
      else
        dependency_arguments << "#{dependent_package} = #{dependent_version}"
      end
    }
    arguments = static_arguments + exclude_arguments + var_arguments + dependency_arguments

    tmpdir = Dir.mktmpdir
    Dir.chdir tmpdir
    FileUtils.mkpath destination_folder
    packagebuild = FPM::Program.new
    ret = packagebuild.run(arguments)
    FileUtils.mv("#{tmpdir}/#{destination_file}","#{destination_folder}/#{destination_file}")
    FileUtils.remove_entry_secure(tmpdir)

    puts "Saving #{package_name}.yaml file"
    open("#{destination_folder}/#{package_name}.yaml", "w") { |file|
      file.puts "package_name: #{package_name}"
      file.puts "version: #{@semver_version}"
      dependency_arguments.delete("-d")
      file.puts "dependencies: #{dependency_arguments}"
    }

    return "Created #{destination_folder}/#{destination_file}"
  end

end
