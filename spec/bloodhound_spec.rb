require "spec_helper"

class User < ActiveRecord::Base
  extend Bloodhound::Searchable

  has_many :products

  bloodhound do |search|
    search.field(:first_name, :attribute => "lower(users.first_name)") {|value| value.downcase }
    search.field :last_name
    search.field :product, :attribute => "products.name", :joins => :products, :group => column_names.join(",")
    search.field :available_product, :type => :boolean,
                                     :attribute => "products.available",
                                     :fuzzy => false,
                                     :joins => :products,
                                     :group => column_names.join(",")
  end
end

class Product < ActiveRecord::Base
  extend Bloodhound::Searchable

  belongs_to :user

  bloodhound do |search|
    search.field :name
    search.field :value
    search.field :available, :type => :boolean, :fuzzy => false

    search.keyword :sort do |value|
      { :order => "#{search.fields[value.to_sym][:attribute]} DESC" }
    end
  end
end

describe Bloodhound do
  before :all do
    @john = User.create(:first_name => "John", :last_name => "Doe")
    @tv = @john.products.create(:name => "Rubber Duck", :value => 10)
    @ducky = @john.products.create(:name => "TV", :value => 200)
  end

  it "finds a user by first_name, in a case insensitive manner" do
    User.scoped_search("John").should include(@john)
    User.scoped_search("joHN").should include(@john)
  end

  it "uses LIKE '%query%' for fuzzy searches" do
    User.scoped_search("oh").should include(@john)
  end

  it "finds a user by last_name, but only in a case sensitive manner" do
    User.scoped_search("Doe").should include(@john)
    User.scoped_search("Doe").should have(1).element
    User.scoped_search("Smith").should_not include(@john)
  end

  it "can find using key:value pairs for attribuets that define a type" do
    User.scoped_search("available_product:yes").should include(@john)
    User.scoped_search("available_product:no").should_not include(@john)
  end

  it "allows defining arbitrary keywords to create scopes" do
    @john.products.scoped_search("order:name").all.should == [@tv, @ducky]
  end

  it "exposes the fields via bloodhound#attributes" do
    last_name = User.bloodhound.fields[:last_name]
    last_name[:attribute].should == "last_name"
    last_name[:type].should be_nil
    last_name[:fuzzy].should be_true
    last_name[:options].should == {}

    first_name = User.bloodhound.fields[:first_name]
    first_name[:attribute].should == "lower(users.first_name)"
    first_name[:type].should be_nil
    first_name[:fuzzy].should be_true
    first_name[:options].should == {}

    availability = Product.bloodhound.fields[:available]
    availability[:attribute].should == "available"
    availability[:type].should == :boolean
    availability[:fuzzy].should be_false
    availability[:options].should == {}
  end
end
