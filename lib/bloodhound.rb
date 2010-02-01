require "chronic"

class Bloodhound
  VERSION = "0.1"
  ATTRIBUTE_RE = /\s*(?:(?:(\S+):)?(?:"([^"]*)"|'([^']*)'|(\S+)))\s*/.freeze

  def initialize
    @search_fields = {}
  end

  def field(name, options={}, &mapping)
    attribute = options.delete(:attribute) || name.to_s
    fuzzy     = options.delete(:fuzzy) || true
    type      = options.delete(:type)
    @search_fields[name.to_sym] = [attribute, type.try(:to_sym), fuzzy, options, mapping]
  end

  def search_scope(model, query)
    tokenize(query).inject(model) do |model, (key,value)|
      value.nil? ? text_search_for(model, key) : attribute_search_for(model, key, value)
    end
  end

  def text_search_for(model, value)
    return model if @search_fields.empty?

    model = scoped_by_text_search_options(model)

    text_search_conditions = @search_fields.inject([[], {}]) do |conditions, (name,properties)|
      attribute, type, fuzzy, options, mapping = properties

      if fuzzy
        conditions[0] << "#{attribute} LIKE :#{name}"
        conditions[1].update(name.to_sym => (mapping || default_mapping).call("%#{value}%"))
        conditions
      else
        conditions
      end
    end

    model = model.scoped(:conditions => [text_search_conditions[0].join(" OR "),
                                         text_search_conditions[1]])
  end
  private :text_search_for

  def attribute_search_for(model, name, value)
    attribute, type, _, options, mapping = @search_fields.fetch(name.to_sym, [])

    return model if type.nil?

    value = (mapping || default_mapping).call(cast_value(value, type))
    model.scoped(options.merge(:conditions => { attribute.to_s => value }))
  end
  private :attribute_search_for

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

  def scoped_by_text_search_options(model)
    @search_fields.inject(model) do |model, (name,properties)|
      _, _, fuzzy, options, _ = properties
      fuzzy ? model.scoped(options) : model
    end
  end
  private :scoped_by_text_search_options

  def tokenize(query)
    query.scan(ATTRIBUTE_RE).map do |(key,*value)|
      value = value.compact.first
      [key || value, key && value]
    end
  end
  private :tokenize

  module Searchable
    def bloodhound(&block)
      @bloodhound ||= Bloodhound.new
      block ? @bloodhound.tap(&block) : @bloodhound
    end

    def scoped_search(query)
      bloodhound.search_scope(self, query)
    end
  end
end
