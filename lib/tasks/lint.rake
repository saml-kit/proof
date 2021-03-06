# frozen_string_literal: true

namespace :lint do
  begin
    require 'rubocop/rake_task'
    require 'bundler/audit/task'

    RuboCop::RakeTask.new
    Bundler::Audit::Task.new
  rescue LoadError => error
    puts error.message
  end

  desc "run the brakeman vulnerability scanner"
  task :brakeman do
    require 'brakeman'
    Brakeman.run(
      app_path: Rails.root,
      print_report: true,
      pager: false,
      config_file: Rails.root.join("config", "brakeman"),
    )
  end

  desc "run uilinters"
  task(:ui) { sh 'yarn lint' }

  desc "run erb linter"
  task(:erb) { sh 'erblint --lint-all --enable-all-linters' }

  desc "Run linters to check the quality of the code."
  task all: ['bundle:audit', :brakeman, :erb, :rubocop, :ui]
end
