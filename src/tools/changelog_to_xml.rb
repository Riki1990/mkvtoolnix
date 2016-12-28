#!/usr/bin/env ruby

require 'rubygems'
require 'pp'
require 'builder'
require 'rexml/document'
require 'trollop'

require_relative 'modules/changelog'

def create_all_releases_xml changelog
  releases_xml = REXML::Document.new File.new($opts[:releases])
  builder      = Builder::XmlMarkup.new( :indent => $opts[:noindent] ? 0 : 2 )

  node_to_hash = lambda { |xpath|
    begin
      Hash[ *REXML::XPath.first(releases_xml, xpath).elements.collect { |e| [ e.name, e.text ] }.flatten ]
    rescue
      Hash.new
    end
  }

  builder.instruct! :xml, :version => "1.0", :encoding => "UTF-8"

  xml = builder.tag!('mkvtoolnix-releases') do
    builder.tag!('latest-source',      node_to_hash.call("/mkvtoolnix-releases/latest-source"))
    builder.tag!('latest-windows-pre', node_to_hash.call("/mkvtoolnix-releases/latest-windows-pre"))

    builder.tag! 'latest-windows-binary' do
      builder.tag! 'installer-url', node_to_hash.call("/mkvtoolnix-releases/latest-windows-binary/installer-url")
      builder.tag! 'portable-url',  node_to_hash.call("/mkvtoolnix-releases/latest-windows-binary/portable-url")
    end

    changelog.each do |cl_release|
      attributes = { "version" => cl_release[0]}.merge node_to_hash.call("/mkvtoolnix-releases/release[version='#{cl_release[0]}']")

      builder.release attributes do
        builder.changes do
          cl_release[1].each do |entry|
            builder.change(entry[:content], entry.reject { |key| [:version, :content].include? key })
          end
        end
      end
    end
  end

  puts xml
end

def parse_opts
  opts = Trollop::options do
    opt :changelog, "ChangeLog source file",    :type => String, :default => 'ChangeLog'
    opt :releases,  "releases.xml source file", :type => String, :default => 'releases.xml'
    opt :noindent,  "do not indent the XML"
  end

  Trollop::die :changelog, "must be given and exist" if !opts[:changelog] || !File.exist?(opts[:changelog])
  Trollop::die :releases,  "must be given and exist" if !opts[:releases]  || !File.exist?(opts[:releases])

  opts
end

def main
  $opts = parse_opts
  create_all_releases_xml parse_changelog($opts[:changelog])
end

main
