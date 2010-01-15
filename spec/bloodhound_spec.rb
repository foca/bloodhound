require "spec_helper"

describe Bloodhound do
  context "adding fields" do
    it "can specify a type of :string" do
      subject.add_search_field(:some_string, :string)
      { "some_string" => "falafel" }.should be_included_in_extracted_attributes_from("some_string:falafel")
    end

    it "can specify a type of :integer" do
      subject.add_search_field(:some_number, :integer)
      { "some_number" => 1 }.should be_included_in_extracted_attributes_from("some_number:1")
    end

    it "can specify a type of :float" do
      subject.add_search_field(:some_number, :float)
      { "some_number" => 1.5 }.should be_included_in_extracted_attributes_from("some_number:1.5")
    end

    it "can specify a type of :boolean" do
      subject.add_search_field(:some_boolean, :boolean)
      { "some_boolean" => true }.should be_included_in_extracted_attributes_from("some_boolean:true")
    end

    it "can specify a type of :date" do
      subject.add_search_field(:some_date, :date)
      { "some_date" => Date.parse('2010-01-05') }.should be_included_in_extracted_attributes_from("some_date:2010-01-05")
    end

    it "can specifiy a type of :time" do
      subject.add_search_field(:some_time, :time)
      { "some_time" => Time.mktime(2010, 1, 5, 12, 0, 0) }.should be_included_in_extracted_attributes_from("some_time:'2010-01-05 12:00:00'")
    end

    it "can specify a type of :text" do
      subject.add_search_field(:some_text, :text)
      { "some_text" => "Hello world" }.should be_included_in_extracted_attributes_from("some_text:'Hello world'")
    end

    it "defaults to a :string field" do
      subject.add_search_field(:some_string)
      { "some_string" => "falafel" }.should be_included_in_extracted_attributes_from("some_string:falafel")
    end
  end

  context "matching quoted values" do
    before { subject.add_search_field(:foo) }

    it "matches unquoted values" do
      { "foo" => "bar" }.should be_included_in_extracted_attributes_from("foo:bar")
      { "foo" => "b'a'r" }.should be_included_in_extracted_attributes_from("foo:b'a'r")
      { "foo" => "ba'r" }.should be_included_in_extracted_attributes_from("foo:ba'r")
    end

    it "matches values within double quotes" do
      { "foo" => "this is awesome" }.should be_included_in_extracted_attributes_from(%Q(foo:"this is awesome"))
      { "foo" => "this is 'tricky'" }.should be_included_in_extracted_attributes_from(%Q(foo:"this is 'tricky'"))
      { "foo" => "'this is even trickier'" }.should be_included_in_extracted_attributes_from(%Q(foo:"'this is even trickier'"))
    end

    it "matches values within single quotes" do
      { "foo" => 'this is awesome' }.should be_included_in_extracted_attributes_from(%Q(foo:'this is awesome'))
      { "foo" => 'this is "tricky"' }.should be_included_in_extracted_attributes_from(%Q(foo:'this is "tricky"'))
      { "foo" => '"this is even trickier"' }.should be_included_in_extracted_attributes_from(%Q(foo:'"this is even trickier"'))
    end
  end

  context "casting values" do
    it "matches 'yes', 'true', 'y', 'no', 'false', and 'n' as boolean values" do
      subject.add_search_field(:foo, :boolean)
      { "foo" => true }.should be_included_in_extracted_attributes_from("foo:yes")
      { "foo" => true }.should be_included_in_extracted_attributes_from("foo:y")
      { "foo" => true }.should be_included_in_extracted_attributes_from("foo:true")
      { "foo" => false }.should be_included_in_extracted_attributes_from("foo:no")
      { "foo" => false }.should be_included_in_extracted_attributes_from("foo:n")
      { "foo" => false }.should be_included_in_extracted_attributes_from("foo:false")
    end

    it "parses integers as Integer objects" do
      subject.add_search_field(:foo, :integer)
      subject.add_search_field(:bar, :integer)
      { "foo" => 1, "bar" => 2 }.should be_included_in_extracted_attributes_from("foo:1 bar:2.8")
    end

    it "parses decimal values as Float objects" do
      subject.add_search_field(:foo, :float)
      { "foo" => 1.5 }.should be_included_in_extracted_attributes_from("foo:1.5")
    end

    it "parses dates as instances of Date" do
      subject.add_search_field(:foo, :date)
      { "foo" => Date.today }.should be_included_in_extracted_attributes_from("foo:today")
    end

    it "parses times as instances of Time" do
      subject.add_search_field(:foo, :time)
      { "foo" => Time.mktime(2010, 1, 5, 12, 0, 0) }.should be_included_in_extracted_attributes_from("foo:2010-01-05 12:00:00")
    end
  end

  context "processing matched values with user-defined lambdas" do
    it "lets you convert matched values according to your business rules" do
      subject.add_search_field(:incomplete, :boolean, "complete") {|value| not value }
      { "complete" => false }.should be_included_in_extracted_attributes_from("incomplete:yes")
    end
  end
end
