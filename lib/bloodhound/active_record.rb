require "bloodhound"

module ActiveRecord
  class Bloodhound < ::Bloodhound
    def initialize
      super()
      @extra_options = {}
    end

    def add_search_field(name, type=:string, attribute=name, options={}, &mapping)
      super(name, type, attribute, &mapping)
      @extra_options[attribute.to_s] = options
    end

    def attributes_from(query)
      super(query).inject({}) do |finder_options, (name, value)|
        finder_options[:conditions] ||= {}
        finder_options[:conditions].update(name => value)
        finder_options.update(@extra_options.fetch(name, {}))
        finder_options
      end
    end
  end
end

module Bloodhound::Searchable
  def bloodhound
    @bloodhound ||= ActiveRecord::Bloodhound.new
  end

  def search_field(name, options={}, &mapping)
    attribute = options.delete(:attribute) || name
    type      = options.delete(:type) || :string
    bloodhound.add_search_field(name, type, attribute, options, &mapping)
  end

  def self.extended(model)
    model.columns.each do |column|
      next if column.name.to_s =~ /_?id$/
      model.search_field column.name, :type => column.type
    end
  end
end
