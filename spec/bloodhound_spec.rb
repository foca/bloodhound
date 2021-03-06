require "spec_helper"

class User < ActiveRecord::Base
  extend Bloodhound::Searchable

  has_many :products

  bloodhound do |search|
    search.field :first_name
    search.alias_field :name, :first_name
    search.field :last_name
    search.field :insensitive_last_name, :attribute => "last_name", :case_sensitive => false
    search.field :substringed_last_name, :attribute => "last_name", :match_substring => true
    search.field :available_product, :type => :boolean,
                                     :attribute => "products.available",
                                     :include => :products

    search.text_search "first_name", "last_name", "products.name", :include => :products
  end
end

class Product < ActiveRecord::Base
  extend Bloodhound::Searchable

  belongs_to :user

  bloodhound do |search|
    search.text_search "products.name", "products.value"

    search.field :name
    search.field :value, :type => :decimal
    search.field :available, :type => :boolean

    search.keyword :sort do |value|
      { :order => "#{search.fields[value.to_sym][:attribute]} DESC" }
    end
  end
end

describe Bloodhound do
  before :all do
    @john = User.create(:first_name => "John", :last_name => "Doe")
    @ducky = @john.products.create(:name => "Rubber Duck", :value => 10)
    @tv = @john.products.create(:name => "TV", :value => 200)
  end

  it "finds a user by first_name" do
    User.scopes_for_query("first_name:John").should include(@john)
  end

  it "finds a user by first_name, using an alias" do
    User.scopes_for_query("name:John").should include(@john)
  end

  it "finds by text search" do
    Product.scopes_for_query("duck rubber").should include(@ducky)
  end

  it "finds a user by last_name, but only in a case sensitive manner" do
    User.scopes_for_query("last_name:Doe").should include(@john)
    User.scopes_for_query("last_name:Doe").should have(1).element
  end

  it "can find using case insensitive search" do
    User.scopes_for_query("insensitive_last_name:doe").should include(@john)
    User.scopes_for_query("insensitive_last_name:doe").should have(1).element
  end

  it "can find matching substrings" do
    User.scopes_for_query("substringed_last_name:oe").should include(@john)
    User.scopes_for_query("substringed_last_name:oe").should have(1).element
  end

  it "can find using key:value pairs for attribuets that define a type" do
    User.scopes_for_query("available_product:yes").should include(@john)
    User.scopes_for_query("available_product:no").should_not include(@john)
  end

  it "allows defining arbitrary keywords to create scopes" do
    @john.products.scopes_for_query("sort:name").all.should == [@tv, @ducky]
  end

  it "allows to search by numeric fields with greater than or lower than modifiers" do
    @john.products.scopes_for_query("value:=10").should include(@ducky)
    @john.products.scopes_for_query("value:=10").should have(1).element
    @john.products.scopes_for_query("value:10").should include(@ducky)
    @john.products.scopes_for_query("value:10").should have(1).element
    @john.products.scopes_for_query("value:>100").should include(@tv)
    @john.products.scopes_for_query("value:>100").should have(1).element
    @john.products.scopes_for_query("value:<100").should include(@ducky)
    @john.products.scopes_for_query("value:<100").should have(1).element
    @john.products.scopes_for_query("value:>200").should have(0).elements
    @john.products.scopes_for_query("value:>=200").should include(@tv)
    @john.products.scopes_for_query("value:>=200").should have(1).element
  end
end
