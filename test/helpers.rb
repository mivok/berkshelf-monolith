require 'fileutils'
require 'pathname'

module Monolith
  module TestHelpers
    def tmp_path
      Pathname.new(File.expand_path("../tmp", __FILE__))
    end

    def clean_tmp_path
      FileUtils.rm_rf(tmp_path)
      FileUtils.mkdir_p(tmp_path)
    end

    def setup_tmp_git_repo
      # Makes the test directory into a git repo for testing excludes
      Dir.chdir(tmp_path) do
        %x|git init|
      end
    end

    def make_git_repo(name)
      # Makes an example git repo with a single file in and one commit
      repo_path = tmp_path.join("git", name)
      FileUtils.mkdir_p(repo_path)
      Dir.chdir(repo_path) do
        %x|git init|
        File.open('metadata.rb', 'w') do |f|
          f.puts "name '#{name}'"
        end
        %x|git add metadata.rb|
        %x|git config --local user.name Me|
        %x|git config --local user.email me@example.com|
        %x|git commit -m "Test commit"|
        %x|git remote add origin "git@git.example.com:#{name}"|
      end
      repo_path
    end

    def make_change_git(name)
      repo_path = tmp_path.join("git", name)
      Dir.chdir(repo_path) do
        File.open('test.txt', 'w') do |f|
          f.puts 'Testing'
        end
        %x|git add test.txt|
        %x|git commit --author "Me <me@example.com>" -m "Update"|
      end
    end

    def make_path_cookbook(name)
      # Makes an example git repo with a single file in and one commit
      cb_path = tmp_path.join("cookbooks", name)
      FileUtils.mkdir_p(cb_path)
      Dir.chdir(cb_path) do
        File.open('metadata.rb', 'w') do |f|
          f.puts "name '#{name}'"
        end
      end
      cb_path
    end

    def make_berksfile(types)
      File.open(tmp_path.join('Berksfile'), 'w') do |berksfile|
        berksfile.puts "source 'https://supermarket.chef.io/'"
        types.each do |type|
          if type == :git
            repo_path = make_git_repo('test_git')
            berksfile.puts("cookbook 'test_git', :git => '#{repo_path}'")
          elsif type == :path
            cb_path = make_path_cookbook('test_path')
            berksfile.puts("cookbook 'test_path', :path => '#{cb_path}'")
          elsif type == :nested_community
            cb_path = make_path_cookbook('test_nested')
            berksfile.puts("cookbook 'test_nested', :path => '#{cb_path}'")
            # Note: testmh is an arbitrary cookbook that exists on
            # supermarket, and could be replaced by any other cookbook as long
            # as the tests are updated appropriately.
            add_metadata_dependency(cb_path, 'testmh')
          end
        end
      end

      if block_given?
        Dir.chdir(tmp_path) do
          yield
        end
      end
    end

    def add_metadata_dependency(cookbook_path, cookbook_name)
      Dir.chdir(cookbook_path) do
        File.open('metadata.rb', 'a') do |f|
          f.puts "depends '#{cookbook_name}'"
        end
      end
    end
  end
end
