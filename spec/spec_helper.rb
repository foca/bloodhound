require "spec"
require "ostruct"
require "bloodhound"

Spec::Runner.configure do |config|
  module CustomMatchers
    def be_included_in_extracted_attributes_from(attribute_string)
      simple_matcher :other_set_of_attributes do |given|
        expected = subject.attributes_from(attribute_string)
        given.each do |key, value|
          expected.fetch(key).should == value
        end
      end
    end
  end

  config.include CustomMatchers
end
