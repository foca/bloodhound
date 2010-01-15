require "spec_helper"
require "bloodhound/active_record"

describe ActiveRecord::Bloodhound do
  it "returns a hash with { :conditions => {keys matched} } instead of just the keys" do
    subject.add_search_field(:foo)
    subject.attributes_from("foo:bar").should == { :conditions => { "foo" => "bar" } }
  end

  it "allows for extra options, that get merged into the return hash" do
    subject.add_search_field(:user, :string, "users.name", :joins => :users)
    subject.attributes_from("user:'John Doe'").should == {
      :joins => :users,
      :conditions => { "users.name" => "John Doe" }
    }
  end
end

describe Bloodhound::Searchable do
  Column = Struct.new(:name, :type)

  class MockModel
    def self.columns
      [Column.new(:id, :integer), Column.new(:name, :string), Column.new(:user_id, :integer)]
    end

    extend Bloodhound::Searchable
  end

  it "allows accessing the bloodhound object in the model by calling Model.bloodhound" do
    MockModel.bloodhound.should be_an(ActiveRecord::Bloodhound)
  end

  it "adds search fields for the non-id fields in the model" do
    conditions = MockModel.bloodhound.attributes_from("name:John id:3 user_id:5").fetch(:conditions)
    conditions.should_not have_key("id")
    conditions.should_not have_key("user_id")
  end

  it "allows you to add search fields with a more ActiveRecord-ish syntax" do
    MockModel.search_field :user, :type => :string, :attribute => "users.name"
    MockModel.bloodhound.attributes_from("user:John").should == { :conditions => { "users.name" => "John" } }
  end
end
