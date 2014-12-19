require 'parslet'

module Log2mail
  module Config

    class ParseError < Log2mail::Error
      def initialize( opts )
        @opts = opts
      end
      def original
        @opts[:exception]
      end
      def to_s
        'File \'' + @opts[:filename] + '\': ' + ($verbose ? original.cause.ascii_tree : original.to_s)
      end
    end

    class Transform < Parslet::Transform

      rule(:quoted_string   => simple(:value)) { value.to_s.gsub('\\"', '"') }
      rule(:unquoted_string => simple(:value)) { value.to_s.strip }
      rule(:integer         => simple(:value)) { value.to_i }

      rule(:attribute_name => simple(:key), :attribute_value => simple(:value)) do
        Attribute.new( key, value )
      end

      rule(:section_name => simple(:key), :section_value => simple(:value)) do
        Section.new( key, value )
      end
      rule(:section_name => simple(:key)) do
        Section.new( key )
      end

      rule(:section => sequence(:values)) { |dict| merge_values( dict[:values] ) }

      def self.merge_values( values )
        values.reduce do |v1, v2|
          fail "v1 must be a Section" unless v1.instance_of?(Section)
          case v2
          when Attribute
            v1.attrs << v2
            v1
          when Section
            v1.attrs << v2
            v1
          else
            fail "Unsupported value class: #{v1.class}: #{v1.inspect}"
          end
        end
        values.first
      end

      rule(:section => simple(:section)) do
        fail "Unsupported section class: #{section.class}" unless section.instance_of?(Section)
        section
      end

      rule(:config => sequence(:sections)) do
        Config.new(sections)
      end

      rule(:config => simple(:comment)) { Config.new }

    end

    class Parser < Parslet::Parser

      rule(:config)           { block.repeat.as(:config) }
      root(:config)

      rule(:block)            { (defaults_section | file_section).as(:section) | eol }

      rule(:defaults_section) { defaults_section_head >> defaults_section_content }
      rule(:file_section)     { file_section_head >> file_section_content }
      rule(:defaults_section_content) { ( mailto_section.as(:section) | pattern_section.as(:section) | attribute | eol ).repeat }
      rule(:file_section_content)     { ( pattern_section.as(:section) | attribute | eol ).repeat }

      rule(:pattern_section)          { pattern_section_head >> pattern_section_content }
      rule(:pattern_section_content)  { ( mailto_section.as(:section) | attribute | eol ).repeat }

      rule(:mailto_section)           { mailto_section_head >> mailto_section_content }
      rule(:mailto_section_content)   { attributes }

      def line_expression( expr )
        space? >> expr >> eol
      end

      def equation( name, value )
        line_expression( name >> space? >> str('=') >> space? >> value )
      end

      rule(:defaults_section_head) { line_expression( str('defaults').as(:section_name) ) }
      rule(:file_section_head)     { equation( str('file').as(:section_name), value.as(:section_value)) }
      rule(:mailto_section_head)   { equation( str('mailto').as(:section_name), value.as(:section_value)) }
      rule(:pattern_section_head)  { equation( str('pattern').as(:section_name), value.as(:section_value)) }

      rule(:attribute)         { equation( valid_attr_name.as(:attribute_name), value.as(:attribute_value) ) }
      # rule(:mailto_attribute)  { equation( str('mailto').as(:attribute_name), value.as(:attribute_value)) }
      # rule(:pattern_attribute) { equation( str('pattern').as(:attribute_name), value.as(:attribute_value)) }

      rule(:attributes)       { attribute.repeat }
      rule(:valid_attr_name)  { ATTRIBUTES.map{|a| str(a.to_s)}.reduce(&:|) }

      rule(:value)            { quoted_string | integer | string_value }
      rule(:string_value)     { (newline.absent? >> comment.absent? >> any).repeat.as(:unquoted_string) }
      rule(:integer)          { match['0-9'].repeat(1).as(:integer) }

      rule(:escaped_quote)    { str('\\"') }
      rule(:quoted_string)    { quote >> ( escaped_quote | quote.absent? >> any ).repeat.as(:quoted_string) >> quote }

      rule(:comment)          { str('#') >> ( newline.absent? >> any ).repeat }
      rule(:newline)          { str("\n") >> str("\r").maybe }
      rule(:quote)            { str('"') | str('\'') }
      rule(:space)            { match(' ').repeat(1) }
      rule(:space?)           { space.maybe }

      rule(:eol)              { space? >> comment.maybe >> newline }

      def parse_snippets( snippets )
        fail(ArgumentError, "Need ConfigFileSnippets") unless snippets.instance_of?(Array) and snippets.all? {|s| s.instance_of?(ConfigFileSnippet)}
        parsed_tree = {}
        snippets.each do |snippet|
          begin
            parsed_tree.merge! parse(snippet.to_s) do |key, oldval, newval|
              Array(oldval) + Array(newval)
            end
          rescue Parslet::ParseFailed
            fail ParseError.new( filename: snippet.filename, exception: $! )
          end
        end
        Transform.new.apply( parsed_tree )
      end

      def parse_and_transform( text )
        Transform.new.apply parse(text)
      rescue Parslet::ParseFailed
        raise
      end

    end

  end
end
