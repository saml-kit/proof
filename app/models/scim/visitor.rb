# frozen_string_literal: true

module Scim
  class Visitor
    def initialize(clazz, mapper = {})
      @clazz = clazz
      @mapper = mapper
    end

    def visit(node)
      case node.operator
      when :and
        visit(node.left).merge(visit(node.right))
      when :or
        visit(node.left).or(visit(node.right))
      when :eq
        @clazz.where(attr_for(node) => value_from(node))
      when :ne
        @clazz.where.not(attr_for(node) => value_from(node))
      when :co
        @clazz.where("#{attr_for(node)} like ?", "%#{value_from(node)}%")
      when :sw
        @clazz.where("#{attr_for(node)} like ?", "#{value_from(node)}%")
      when :ew
        @clazz.where("#{attr_for(node)} like ?", "%#{value_from(node)}")
      when :gt
        @clazz.where("#{attr_for(node)} > ?", cast_value_from(node))
      when :ge
        @clazz.where("#{attr_for(node)} >= ?", cast_value_from(node))
      when :lt
        @clazz.where("#{attr_for(node)} < ?", cast_value_from(node))
      when :le
        @clazz.where("#{attr_for(node)} <= ?", cast_value_from(node))
      when :pr
        @clazz.where.not(attr_for(node) => nil)
      else
        @clazz.none
      end
    end

    private

    def value_from(node)
      node.value
    end

    def cast_value_from(node)
      attr = attr_for(node)
      value = value_from(node)
      type = @clazz.columns_hash[attr.to_s].type

      case type
      when :datetime
        DateTime.parse(value)
      else
        value.to_s
      end
    end

    def attr_for(node)
      @mapper[node.attribute] || node.attribute
    end
  end
end
