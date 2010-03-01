require "chronic"
require "active_record"

class Bloodhound
  VERSION = "0.3"
  ATTRIBUTE_RE = /\s*(?:(?:(\S+):)?(?:"([^"]*)"|'([^']*)'|(\S+)))\s*/.freeze

  attr_reader :fields

  def initialize(model)
    @model = model
    @fields = {}
  end

  def field(name, options={}, &mapping)
    @fields[name.to_sym] = field = {
      :attribute       => options.fetch(:attribute, name).to_s,
      :type            => options.fetch(:type, :string).to_sym,
      :case_sensitive  => options.fetch(:case_sensitive, true),
      :match_substring => options.fetch(:match_substring, false),
      :options         => options.except(:attribute, :type, :case_sensitive, :match_substring),
      :mapping         => mapping || default_mapping
    }

    define_field(name, field)
  end

  def define_field(name, field)
    define_scope(name) do |value|
      field[:options].merge(:conditions => setup_conditions(field, value))
    end
  end
  private :define_field

  def alias_field(name, other_field)
    @fields[name.to_sym] = @fields[other_field.to_sym]
    define_field(name, @fields[name.to_sym])
  end

  def text_search(*fields)
    options = fields.extract_options!
    fields = fields.map {|f| "LOWER(#{f}) LIKE :value" }.join(" OR ")

    define_scope "text_search" do |value|
      options.merge(:conditions => [fields, { :value => "%#{value.downcase}%" }])
    end
  end

  def keyword(name, &block)
    define_scope(name, &block)
  end

  def search(query)
    self.class.tokenize(query).inject(@model) do |model, (key,value)|
      key, value = "text_search", key if value.nil?

      if model.respond_to?(scope_name_for(key))
        model.send(scope_name_for(key), value)
      else
        model
      end
    end
  end

  def define_scope(name, &scope)
    @model.send(:named_scope, scope_name_for(name), scope)
  end
  private :define_scope

  def scope_name_for(key)
    "bloodhound_for_#{key}"
  end
  private :scope_name_for

  def default_mapping
    lambda {|value| value }
  end
  private :default_mapping

  def cast_value(value, type)
    case type
    when :boolean
      { "true"  => true,
        "yes"   => true,
        "y"     => true,
        "false" => false,
        "no"    => false,
        "n"     => false }.fetch(value.downcase, true)
    when :float, :decimal, :integer
      NumericExpression.new(value, type)
    when :date
      Date.parse(Chronic.parse(value, :context => :past).to_s)
    when :time, :datetime
      Chronic.parse(value)
    else
      value
    end
  end
  private :cast_value

  def setup_conditions(field, value)
    value = field[:mapping].call(cast_value(value, field[:type]))
    case field[:type]
    when :string
      conditions_for_string_search(field, value)
    when :float, :decimal, :integer
      conditions_for_numeric(field, value)
    else
      { field[:attribute] => value }
    end
  end
  private :setup_conditions

  def conditions_for_numeric(field, value)
    [ "#{field[:attribute]} #{value.condition} ?", value.to_s ]
  end

  def conditions_for_string_search(field, value)
    if field[:case_sensitive]
      field_to_search = field[:attribute]
      value_to_search = value
    else
      field_to_search = "lower(#{field[:attribute]})"
      value_to_search = value.downcase
    end
    if field[:match_substring]
      value_to_search = "%#{value_to_search}%"
    end
    [ "#{field_to_search} like ?", value_to_search ]
  end
  private :conditions_for_string_search

  def self.tokenize(query)
    query.scan(ATTRIBUTE_RE).map do |(key,*value)|
      value = value.compact.first
      [key || value, key && value]
    end
  end

  module Searchable
    def bloodhound(&block)
      @bloodhound ||= Bloodhound.new(self)
      block ? @bloodhound.tap(&block) : @bloodhound
    end

    def scopes_for_query(query)
      bloodhound.search(query)
    end
  end

  class NumericExpression
    attr_reader :value, :condition

    def initialize(value, type)
      parts = value.scan(/(?:[=<>]+|(?:\d|\.)+)/)[0,2]
      # Kernel#Float is a bit more lax about parsing numbers, like
      # Integer(0.0) fails, when we just want it interpreted as a zero
      @value = Float(parts.last)
      @value = @value.to_i if type == :integer
      @condition = sanitize_condition(parts.first)
    end

    def sanitize_condition(cond)
      valid = %w(= == > < <= >= <>)
      valid.include?(cond) ? cond : "="
    end

    def to_i
      value.to_i
    end

    def to_f
      value.to_f
    end

    def to_s
      value.to_s
    end
  end
end
