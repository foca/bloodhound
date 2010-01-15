require "chronic"

class Bloodhound
  VERSION = "0.1"
  ATTRIBUTE_RE = /\s*(\S+):(?:"([^"]*)"|'([^']*)'|(\S+))\s*/.freeze

  def initialize
    @mappings = {}
  end

  def add_search_field(name, type=:string, attribute=name, &mapping)
    @mappings[name.to_sym] = [attribute, type.to_sym, mapping]
  end

  def attributes_from(query)
    parse_query(query).inject({}) do |conditions, (key,value)|
      attribute, type, mapping = @mappings.fetch(key.to_sym, [])

      if attribute && type
        conditions[attribute.to_s] = (mapping || default_mapping).call(cast_value(value, type))
      end

      conditions
    end
  end

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

  def parse_query(query)
    query.scan(ATTRIBUTE_RE).map do |(key,*value)|
      [key, value.compact.first]
    end
  end
  private :parse_query
end
