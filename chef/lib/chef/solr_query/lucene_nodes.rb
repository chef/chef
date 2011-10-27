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

module Lucene
  SEP = "__=__"

  class Term < Treetop::Runtime::SyntaxNode
    def to_array
      "T:#{self.text_value}"
    end

    def transform
      self.text_value
    end
  end

  class Field < Treetop::Runtime::SyntaxNode
    def to_array
      field = self.elements[0].text_value
      term = self.elements[1].to_array
      "(F:#{field} #{term})"
    end

    def transform
      field = self.elements[0].text_value
      term = self.elements[1]
      if term.is_a? Phrase
        str = term.transform
        # remove quotes
        str = str[1 ... (str.length - 1)]
        "content:\"#{field}#{SEP}#{str}\""
      else
        "content:#{field}#{SEP}#{term.transform}"
      end
    end
  end

  class FieldRange < Treetop::Runtime::SyntaxNode

    def to_array
      field = self.elements[0].text_value
      range_start = self.elements[1].to_array
      range_end = self.elements[2].to_array
      "(FR:#{field} #{left}#{range_start}#{right} #{left}#{range_end}#{right})"
    end

    def transform
      field = self.elements[0].text_value
      range_start = self.elements[1].transform
      range_end = self.elements[2].transform
      # FIXME: handle special cases for missing start/end
      if ("*" == range_start && "*" == range_end)
        "content:#{field}#{SEP}*"
      elsif "*" == range_end
        "content:#{left}#{field}#{SEP}#{range_start} TO #{field}#{SEP}\\ufff0#{right}"
      elsif "*" == range_start
        "content:#{left}#{field}#{SEP} TO #{field}#{SEP}#{range_end}#{right}"
      else
        "content:#{left}#{field}#{SEP}#{range_start} TO #{field}#{SEP}#{range_end}#{right}"
      end
    end

  end

  class InclFieldRange < FieldRange
    def left
      "["
    end
    def right
      "]"
    end
  end

  class ExclFieldRange < FieldRange
    def left
      "{"
    end
    def right
      "}"
    end
  end

  class RangeValue < Treetop::Runtime::SyntaxNode
    def to_array
      self.text_value
    end

    def transform
      to_array
    end
  end

  class FieldName < Treetop::Runtime::SyntaxNode
    def to_array
      self.text_value
    end

    def transform
      to_array
    end
  end


  class Body < Treetop::Runtime::SyntaxNode
    def to_array
      self.elements.map { |x| x.to_array }.join(" ")
    end

    def transform
      self.elements.map { |x| x.transform }.join(" ")
    end
  end

  class Group < Treetop::Runtime::SyntaxNode
    def to_array
      "(" + self.elements[0].to_array + ")"
    end

    def transform
      "(" + self.elements[0].transform + ")"
    end
  end

  class BinaryOp < Treetop::Runtime::SyntaxNode
    def to_array
      op = self.elements[1].to_array
      a = self.elements[0].to_array
      b = self.elements[2].to_array
      "(#{op} #{a} #{b})"
    end

    def transform
      op = self.elements[1].transform
      a = self.elements[0].transform
      b = self.elements[2].transform
      "#{a} #{op} #{b}"
    end
  end

  class AndOperator < Treetop::Runtime::SyntaxNode
    def to_array
      "OP:AND"
    end

    def transform
      "AND"
    end
  end

    class OrOperator < Treetop::Runtime::SyntaxNode
    def to_array
      "OP:OR"
    end

    def transform
      "OR"
    end
  end

  class FuzzyOp < Treetop::Runtime::SyntaxNode
    def to_array
      a = self.elements[0].to_array
      param = self.elements[1]
      if param
        "(OP:~ #{a} #{param.to_array})"
      else
        "(OP:~ #{a})"
      end
    end

    def transform
      a = self.elements[0].transform
      param = self.elements[1]
      if param
        "#{a}~#{param.transform}"
      else
        "#{a}~"
      end
    end
  end

  class BoostOp < Treetop::Runtime::SyntaxNode
    def to_array
      a = self.elements[0].to_array
      param = self.elements[1]
      "(OP:^ #{a} #{param.to_array})"
    end

    def transform
      a = self.elements[0].transform
      param = self.elements[1]
      "#{a}^#{param.transform}"
    end
  end

  class FuzzyParam < Treetop::Runtime::SyntaxNode
    def to_array
      self.text_value
    end

    def transform
      self.text_value
    end
  end

  class UnaryOp < Treetop::Runtime::SyntaxNode
    def to_array
      op = self.elements[0].to_array
      a = self.elements[1].to_array
      "(#{op} #{a})"
    end

    def transform
      op = self.elements[0].transform
      a = self.elements[1].transform
      spc = case op
            when "+", "-"
              ""
            else
              " "
            end
      "#{op}#{spc}#{a}"
    end

  end

  class NotOperator < Treetop::Runtime::SyntaxNode
    def to_array
      "OP:NOT"
    end

    def transform
      "NOT"
    end

  end

  class RequiredOperator < Treetop::Runtime::SyntaxNode
    def to_array
      "OP:+"
    end

    def transform
      "+"
    end

  end

  class ProhibitedOperator < Treetop::Runtime::SyntaxNode
    def to_array
      "OP:-"
    end

    def transform
      "-"
    end
  end

  class Phrase < Treetop::Runtime::SyntaxNode
    def to_array
      "STR:#{self.text_value}"
    end

    def transform
      "#{self.text_value}"
    end
  end
end
