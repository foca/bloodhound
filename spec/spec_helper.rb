require "spec"
require "ostruct"
require "bloodhound"
require "active_record"

ActiveRecord::Base.establish_connection(
  :adapter => "sqlite3",
  :database => "spec/test.db"
)

#ActiveRecord::Base.logger = Logger.new(STDOUT)

ActiveRecord::Base.connection.tables.each do |table|
  ActiveRecord::Base.connection.drop_table(table)
end

ActiveRecord::Schema.define(:version => 1) do
  create_table :users do |t|
    t.string :first_name
    t.string :last_name
  end

  create_table :products do |t|
    t.string :name
    t.integer :value
    t.boolean :available, :default => true
    t.belongs_to :user
  end
end
