# frozen_string_literal: true

module Scim
  class Visitor < Scim::Kit::V2::Filter::Visitor
    include Varkon

    def initialize(clazz, mapper = {})
      @clazz = clazz
      @mapper = mapper
    end

    protected

    def visit_and(node)
      visit(node.left).merge(visit(node.right))
    end

    def visit_or(node)
      visit(node.left).or(visit(node.right))
    end

    def visit_equals(node)
      query_for(node, attr_for(node) => node.value)
    end

    def visit_not_equals(node)
      if node.not?
        @clazz.where(attr_for(node) => node.value)
      else
        @clazz.where.not(attr_for(node) => node.value)
      end
    end

    def visit_contains(node)
      query_for(
        node,
        "#{attr_for(node)} LIKE ?",
        "%#{escape_sql_wildcards(node.value)}%"
      )
    end

    def visit_starts_with(node)
      query_for(
        node,
        "#{attr_for(node)} LIKE ?",
        "#{escape_sql_wildcards(node.value)}%"
      )
    end

    def visit_ends_with(node)
      query_for(
        node,
        "#{attr_for(node)} LIKE ?",
        "%#{escape_sql_wildcards(node.value)}"
      )
    end

    def visit_greater_than(node)
      query_for(node, "#{attr_for(node)} > ?", cast_value_from(node))
    end

    def visit_greater_than_equals(node)
      query_for(node, "#{attr_for(node)} >= ?", cast_value_from(node))
    end

    def visit_less_than(node)
      query_for(node, "#{attr_for(node)} < ?", cast_value_from(node))
    end

    def visit_less_than_equals(node)
      query_for(node, "#{attr_for(node)} <= ?", cast_value_from(node))
    end

    def visit_presence(node)
      if node.not?
        @clazz.where(attr_for(node) => nil)
      else
        @clazz.where.not(attr_for(node) => nil)
      end
    end

    def visit_unknown(_node)
      @clazz.none
    end

    def cast_value_from(node)
      case @clazz.columns_hash[attr_for(node).to_s].type
      when :datetime
        DateTime.parse(node.value).utc
      else
        node.value.to_s
      end
    end

    def attr_for(node)
      @mapper.fetch(node.attribute, node.attribute)
    end

    def query_for(node, *conditions)
      node.not? ? @clazz.where.not(*conditions) : @clazz.where(*conditions)
    end
  end
end
