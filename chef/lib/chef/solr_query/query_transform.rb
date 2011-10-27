#
# Author:: Seth Falcon (<seth@opscode.com>)
# Copyright:: Copyright (c) 2010-2011 Opscode, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
require 'treetop'
require 'chef/solr_query/lucene_nodes'

class Chef
  class Exceptions
    class QueryParseError < StandardError
    end
  end
end

class Chef
  class SolrQuery
    class QueryTransform
      @@base_path = File.expand_path(File.dirname(__FILE__))
      Treetop.load(File.join(@@base_path, 'lucene.treetop'))
      @@parser = LuceneParser.new

      def self.parse(data)
        tree = @@parser.parse(data)
        msg = "Parse error at offset: #{@@parser.index}\n"
        msg += "Reason: #{@@parser.failure_reason}"
        raise Chef::Exceptions::QueryParseError, msg if tree.nil?
        self.clean_tree(tree)
        tree.to_array
      end

      def self.transform(data)
        return "*:*" if data == "*:*"
        tree = @@parser.parse(data)
        msg = "Parse error at offset: #{@@parser.index}\n"
        msg += "Reason: #{@@parser.failure_reason}"
        raise Chef::Exceptions::QueryParseError, msg if tree.nil?
        self.clean_tree(tree)
        tree.transform
      end

      private

      def self.clean_tree(root_node)
        return if root_node.elements.nil?
        root_node.elements.delete_if do |node|
          node.class.name == "Treetop::Runtime::SyntaxNode"
        end
        root_node.elements.each { |node| self.clean_tree(node) }
      end
    end
  end
end
