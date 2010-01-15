Bloodhound
==========

Simple key:value string conversion to hashes, with type casting.

    require "bloodhound"

    hound = Bloodhound.new
    hound.add_search_field(:name,   :string)
    hound.add_search_field(:age,    :integer)
    hound.add_search_field(:active, :boolean)

    attributes = hound.attributes_from('name:"John Doe" age:22 active:yes')
    attributes #=> { "name" => "John Doe", "age" => 22, "active" => true }

The available types are `:string` (the default), `:integer`, `:float`, `:date`,
`:time`, and `:boolean`. Any other type is treated as a string.

It matches several values as boolean values. 'yes', 'y', and 'true' are all
mapped to `true`, while 'no', 'n', and 'false' are mapped to `false`.

You can customize the hash key returned:

    hound.add_search_field(:user, :string, "users.name")

    attributes = hound.attributes_from('user:"John Doe"')
    attributes #=> { "users.name" => "John Doe" }

It can match dates and times, using [Chronic](http://github.com/mojombo/chronic),
so this is valid:

    hound.add_search_field(:added, :date, "added_on")

    attributes = hound.attributes_from("added:today")
    attributes #=> { "added_on" => Date.today }

Finally, you can also provide processing rules for the parsed value, by passing
a block:

    hound.add_search_field(:inactive, :boolean, "active") {|value| not value }

    attributes = hound.attributes_from("inactive:true")
    attributes #=> { "active" => false }

ActiveRecord integration
------------------------

    require "bloodhound/active_record"

    class Video < ActiveRecord::Base
      extend Bloodhound::Searchable
      named_scope :search, lambda {|query| bloodhound.attributes_from(query) }
    end

The ActiveRecord implementation will automatically define search fields for all
non-id, non-timestamp columns (ie, all except for `id` and `foo_id`).

You can, of course, add those in manually if you need them.

The syntax for defining attributes is a bit more rails-esque:

    class Video < ActiveRecord::Base
      extend Bloodhound::Searchable
      search_field :user, :type => :string, :attribute => "users.login"
    end

The return value of `ActiveRecord::Bloodhound#attributes_from` changes a bit,
and returns a hash directly compatible with ActiveRecord:

    attributes = Video.bloodhound.attributes_from("user:foca")
    attributes #=> { :conditions => { "users.login" => "foca" } }

Any extra options you pass to `search_field` are added into the finder options:

    class Video < ActiveRecord::Base
      extend Bloodhound::Searchable
      search_field :user, :attribute => "users.login", :joins => :user

      belongs_to :user
    end

    attributes = Video.bloodhound.attributes_from("user:foca")
    attributes #=> { :joins => :user,
                     :conditions => { "users.login" => "foca" } }

Install it
----------

    gem install bloodhound

For the active record interface:

    config.gem "bloodhound", :lib => "bloodhound/active_record"

Known problems
--------------

* Chronic is a bit… weird matching some stuff, specially regarding time zones.
* The ActiveRecord 'extra options' won't merge. So if you define two search
  fields with ':joins => :an_association', only the latter will remain. This
  will be fixed in a future release.

License
-------

(The MIT License)

Copyright (c) 2010 Nicolas Sanguinetti, http://nicolassanguinetti.info

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
