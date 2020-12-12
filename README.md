Cache Crispies [![CircleCI](https://circleci.com/gh/codenoble/cache-crispies.svg?style=shield)](https://circleci.com/gh/codenoble/cache-crispies) [![Maintainability](https://api.codeclimate.com/v1/badges/278cfda71defc0bc1d1c/maintainability)](https://codeclimate.com/github/codenoble/cache-crispies/maintainability) [![Test Coverage](https://api.codeclimate.com/v1/badges/278cfda71defc0bc1d1c/test_coverage)](https://codeclimate.com/github/codenoble/cache-crispies/test_coverage)
==============

Speedy Rails JSON serialization with built-in caching.

Why?
----

There are a lot of Rails serializers out there, but there seem to be very few these days that are well maintained and performant. The ones that are, tend to lock you into a specific standard for how to format your JSON responses. And the idea of introducing breaking API changes across the board to a mature Rails app is daunting, to say the least.

In addition, incorporating a caching layer (for performance reasons) into your serializers can be difficult unless you do it at a Rails view layer. And the serialization gems that work at the view layer tend to be slow in comparison to others. So it tends to be a one step forward one step back sort of solution.

In light of all that, this gem was built with these goals in mind:
1. Be fast
2. Support caching in as simple a way as we can
3. Support rollout without causing breaking API changes
4. Avoid the bloat that can lead to slowness and maintenance difficulties

Requirements
------------
- Ruby 2.4–2.6 _(others will likely work but are untested)_
- Rails 5 or 6 _(others may work but are untested)_

Features
--------
- **Fast** even without caching
- **Flexible** lets you serialize data any way you want it
- **Built-in Caching** _(documentation coming soon)_
- **ETags** for easy HTTP caching
- **Simple, Readable DSL**

Configuration
-------------
### ETags
```ruby
CacheCrispies.configure do |conf|
  conf.etags = true
end
```
_`etags` is set to `false` by default._

### Custom Cache Store
```ruby
CacheCrispies.configure do |conf|
  conf.cache_store = ActiveSupport::Cache::DalliStore.new('localhost')
end
```
`cache_store` must be set to something that quacks like a [ActiveSupport::Cache::Store](https://api.rubyonrails.org/classes/ActiveSupport/Cache/Store.html).

_`cache_store` is set to `Rails.cache` by default, or `ActiveSupport::Cache::NullStore.new` if `Rails.cache` is `nil`._

### Custom model cache key
```ruby
CacheCrispies.configure do |conf|
  conf.cache_key_method = :custom_cache_key_method_name
end
```
`cache_key_method` must be set to the name of the method the model responds to and returns a string value.

_`cache_key_method` is set to `:cache_key` by default._

Usage
-----
### A simple serializer
```ruby
class CerealSerializer < CacheCrispies::Base
  serialize :name, :brand
end
```

### A not-so-simple serializer
```ruby
  class CerealSerializer < CacheCrispies::Base
    key :food
    collection_key :food

    do_caching true

    cache_key_addons { |options| options[:be_trendy] }
    dependency_key 'V3'

    serialize :uid, from: :id, to: String
    serialize :name, :company
    serialize :copyright, through: :legal_info
    serialize :spiel do |cereal, _options|
      'Made with whole grains!' if cereal.ingredients[:whole_grains] > 0.000001
    end
    merge :itself, with: MarketingBsSerializer

    nest_in :about do
      nest_in :nutritional_information do
        serialize :calories
        serialize :ingredients, with: IngredientSerializer
      end
    end

    show_if ->(_model, options) { options[:be_trendy] } do
      nest_in :health do
        serialize :organic

        show_if ->(model) { model.organic } do
          serialize :certification
        end
      end
    end

    def certification
      'Totally Not A Scam Certifiers Inc'
    end
  end
```

Put serializer files in `app/serializers/`. For instance this file should be at `app/serializers/cereal_serializer.rb`.

### In your Rails controller
```ruby
class CerealsController
  include CacheCrispies::Controller

  def index
    cereals = Cereal.all
    cache_render CerealSerializer, cereals, custom_option: true
  end
end
```

### Anywhere else
```ruby
CerealSerializer.new(Cereal.first, be_trendy: true).as_json
```

### Output
```json
{
  "uid": "42",
  "name": "Eyeholes",
  "company": "Needful Things",
  "copyright": "© Need Things 2019",
  "spiel": "Made with whole grains!",
  "tagline": "Part of a balanced breakfast",
  "small_print": "This doesn't mean jack-squat",
  "about": {
    "nutritional_information": {
      "calories": 1000,
      "ingredients": [
        {
          "name": "Sugar"
        },
        {
          "name": "Other Kind of Sugar"
        }
      ]
    }
  },
  "health": {
    "organic": false
  }
}
```

A Note About Caching
--------------------
Turning on caching is as simple as adding `do_caching true` to your serialzer. But if you're not familiar with how Rails caching, or caching in general works you could wind up with some real messy caching bugs.

At the very least, you should know that Cache Crispies bases most of it's caching on the `cache_key` method provided by Rails Active Record models. Knowing how `cache_key` works in Rails, along with `touch`, will get you a long way. I'd recommend taking a look at the [Caching with Rails](https://guides.rubyonrails.org/caching_with_rails.html) guide if you're looking for a place to start.

For those looking for more specifics, here is the code that generates a cache key for a serializer instance:
```ruby
[
CACHE_KEY_PREFIX, # "cache-crispies"
serializer.cache_key_base, # an MD5 hash of the contest of the serializer file and all nested serializer files
serializer.dependency_key, # an optional static key
addons_key, # an optional runtime-generated key
cacheable.cache_key # typically ActiveRecord::Base#cache_key
].flatten.compact.join(CACHE_KEY_SEPARATOR) # + is used as the separator
```

### Key Points to Remember
- Caching is completely optional and disabled in serializers by default
- If an object you're serializing doesn't have a `cache_key` method, it won't be cached
- If you want to cache a model, it should have an `updated_at` column
- Editing an `app/serializers/____serializer.rb` file will bust all caches generated by that serializer
- Editing an `app/serializers/____serializer.rb` file will bust all caches generated by other serialiers that nest that serializer
- Changing the `dependency_key` will bust all caches from that serializer
- Not setting the appropriate value in `cache_key_addons` when the same model + serializer pair could produce different output, depending on options or other factors, will result in stale data
- Data will be cached in the `Rails.cache` store by default

How To...
---------
### Use a different JSON key
```ruby
serialize :is_organic, from: :organic?
```

### Use an attribute from an associated object
```ruby
serialize :copyright, through: :legal_info
```
_If the `legal_info` method returns `nil`, `copyright` will also be `nil`._

### Nest another serializer
```ruby
serialize :ingredients, with: IngredientSerializer
```

### Merge attributes from another serializer
```ruby
merge :legal_info, with: LegalInfoSerializer
```

### Force another serializer to be rendered as a single or collection
```ruby
merge :prices, with: PricesSerializer, collection: false
```

### Coerce to another data type
```ruby
serialize :id, to: String
```
Supported data type arguments are
- `String`
- `Integer`
- `Float`
- `BigDecimal`
- `Array`
- `Hash`
- `:bool`, `:boolean`, `TrueClass`, or `FalseClass`

### Nest attributes
```ruby
nest_in :health_info do
  serialize :non_gmo
end
```
_You can nest `nest_in` blocks as deeply as you want._

### Conditionally render attributes
```ruby
show_if (model, options) => { model.low_carb? || options[:trendy] } do
  serialize :keto_certified
end
```
_You can nest `show_if` blocks as deeply as you want._

### Render custom values
```ruby
serialize :fine_print do |model, options|
  model.fine_print || options[:fine_print] || '*Contents may contain lots and lots of sugar'
end
```
or
```ruby
serialize :fine_print

def fine_print
  model.fine_print || options[:fine_print] || '*Contents may contain lots and lots of sugar'
end
```

### Include other data
```ruby
class CerealSerializer < CacheCrispies::Base
  serialize :page

  def page
    options[:page]
  end
end

CerealSerializer.new(cereal, page: 42).as_json
# or
cache_render CerealSerializer, cereal, page: 42
```

### Include metadata
```ruby
  cache_render CerealSerializer, meta: { page: 42 }
```

This would render
```json
{
  "meta": { "page": 42 },
  "cereal": {
    ...
  }
}
```
_Note that metadata is not cached._

### Change the default metadata key
The default metadata key is `meta`, but it can be changed with the `meta_key` option.

```ruby
  cache_render CerealSerializer, meta: { page: 42 }, meta_key: :pagination
```

This would render
```json
{
  "pagination": { "page": 42 },
  "cereal": {
    ...
  }
}
```

### Set custom JSON keys
```ruby
class CerealSerializer < CacheCrispies::Base
  key :breakfast_cereal
  collection_key :breakfast_cereals
end
```
_Note that `collection_key` is the plural of `key` by default._

### Force rendering as a collection or not
By default Cache Crispies will look at whether or not the object you're serializing responds to `#each` in order to determine whether to render it as a collection, where every item in the `Enumerable` object is individually passed to the serializer and returned as an `Array`. Or as a non-collection where the single object is serialized and returned.

But you can override this default behavior by passing `collection: true` or `collection: false` to the `cache_render` method.

This can be useful for things like wrappers around collections that contain metadata about the collection.

```ruby
class CerealListSerializer < CacheCrispies::Base
  nest_in :meta do
    serialize :length
  end

  serialize :cereals, from: :itself, with: CerealSerializer
end

cache_render CerealSerializer, cereals, collection: false
```

### Render a serializer to a `Hash`
```ruby
CerealSerializer.new(Cereal.first, trendy: true).as_json
```

### Enable Caching
```ruby
do_caching true
```

### Customize the Cache Key
```ruby
  cache_key_addons do |options|
    options[:current_user].id
  end
```

By default the model's `cache_key` is the primary thing determining how something will be cached. But sometimes, you need to take other things into consideration to prevent returning stale cache data. This is espcially common when you pass in options that change what's rendered.

Here's an example:
```ruby
class UserSerializer < CacheCrispies::Base
  serialize :display_name

  def display_name
    if options[:current_user] == model
      model.full_name
    else
      model.initials
    end
  end
end
```

In this scenario, you should include `options[:current_user].id` in the `cache_key_addons`. Otherwise, the user's full name could get cached, and users, who shouldn't see it, would.

It is also possible to configure the method CacheCrispies calls on the model via the `config.cacheable_cache_key`
configuration option.

### Bust the Cache Key
```ruby
dependency_key 'V2'
```

Cache Crispies does it's best to be aware of changes to your data and your serializers. Even tracking nested serializers. But, realistically, it can't track everything.

For instance, let's say you have a couple Rails models that have `email` fields. These fields are stored in the database as mixed case strings. But you want them lowercased in your JSON. So you decide to do something like this.

```ruby
module HasEmail
  def email
    model.email.downcase
  end
end

class UserSerializer < CacheCrispies::Base
  include HasEmail

  do_caching true

  serialize :email
end
```

As your app is used, keys are generated and stored with downcased emails. But then you realize that you have trailing whitespace in your emails. So you change your mixin to do `model.email.downcase.strip`. Now you've changed your data, without changing your database, or your serializer. So Cache Crispies doesn't know your data has changed and continues to render the emails with trailing whitespace.

The best solution for this problem is to do something like this:
```ruby
module HasEmail
  CACHE_KEY = 'HasEmail-V2'

  def email
    model.email.downcase
  end
end

class UserSerializer < CacheCrispies::Base
  include HasEmail

  do_caching true
  dependency_key HasEmail::CACHE_KEY

  serialize :email
end
```

Now anytime you change `HasEmail` in a way that should bust the cache, just change the `CACHE_KEY` and you're good.

Detailed Documentation
----------------------
See [rubydoc.info/gems/cache_crispies](https://www.rubydoc.info/gems/cache_crispies/)

Benchmarks and Example Application
----------------------------------
See [github.com/codenoble/cache-crispies-performance-comparison](https://github.com/codenoble/cache-crispies-performance-comparison)

Tips
----
To delete all cache entries in Redis:
`redis-cli --scan --pattern "*cache-crispies*" | xargs redis-cli unlink`

Running Tests Locally
---------------------

We use [https://github.com/thoughtbot/appraisal](Appraisal) to run tests against multiple Rails versions.

```shell
bundle exec appraisal install
bundle exec appraisal rspec
```

Contributing
------------

Feel free to contribute by opening a Pull Request. But before you do, please be sure to follow the steps below.

- Run `bundle exec appraisal install` to update all of the appropriate gemfiles.
- Run `bundle exec appraisal rspec` to ensure all tests are passing.
- Check the `rspec` output around test coverage. Try to maintain `LOC (100.0%) covered`, if at all possible.
- After pushing up your pull request, check the status from [https://circleci.com/](CircleCI) and [https://codeclimate.com/](Code Climate) to ensure they pass.

License
-------
MIT
