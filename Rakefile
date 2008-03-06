# -*- ruby -*-

require 'rubygems'
require 'hoe'
require './lib/marionette.rb'
require './tasks/rspec.rb'
# require Dir[File.join(File.dirname(__FILE__), 'tasks/**/*.rb')].sort.each do |lib|
#   require lib
# end

Hoe.new('marionette', Marionette::VERSION) do |p|
  p.rubyforge_name = 'marionette'
  p.author = 'Adam Jacob'
  p.email = 'adam@hjksolutions.com'
  p.summary = 'A configuration management system'
  p.description = p.paragraphs_of('README.txt', 2..5).join("\n\n")
  p.url = p.paragraphs_of('README.txt', 0).first.split(/\n/)[1..-1]
  p.changes = p.paragraphs_of('History.txt', 0..1).join("\n\n")
end

# vim: syntax=Ruby
