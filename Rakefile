require "bundler/gem_tasks"
require 'rake/testtask'
require 'digitool_to_dspace'


Rake::TestTask.new do |t|
  t.libs.push "lib"
  t.test_files = FileList['test/*_test.rb']
  t.verbose = true
end

task :process do

  input  = ENV['input']
  output = ENV['output']

  DigitoolToDspace::Processor.process_all(input, output)

end