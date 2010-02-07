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
      :attribute => options.fetch(:attribute, name).to_s,
      :type      => options.fetch(:type, :string).to_sym,
      :options   => options.except(:attribute, :type),
      :mapping   => mapping || default_mapping
    }

    define_scope(name) do |value|
      value = field[:mapping].call(cast_value(value, field[:type]))
      field[:options].merge(:conditions => { field[:attribute] => value })
    end
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
    when :integer
      # Kernel#Float is a bit more lax about parsing numbers, like
      # Integer(0.0) fails, when we just want it interpreted as a zero
      Float(value).to_i
    when :float, :decimal
      Float(value)
    when :date
      Date.parse(Chronic.parse(value).to_s)
    when :time, :datetime
      Chronic.parse(value)
    else
      value
    end
  end
  private :cast_value

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
end
