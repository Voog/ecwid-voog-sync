# Ecwid Store to Voog CMS synchronizer

This [Ruby on Rails](http://rubyonrails.org/) based application deals with products synchronization between [Ecwid](http://ecwid.com/). Store and [Voog CMS](http://www.voog.com/).

Original store data is fetched from Ecwid using [Ecwid API v3](http://api.ecwid.com/).

Application sends changed products and categories information to Voog CMS using [Voog API](http://www.voog.com/developers/api).

## Datastructure in Voog CMS

Synced products data setup is using [Voog database tool](http://www.voog.com/support/guides/developers/voog-database-tool).

Every product category is a [elements page](http://www.voog.com/developers/api/resources/pages) in Voog.

Some additional attributes are stored to category page using [Voog custom data field](http://www.voog.com/developers/templating/javascripts/customdata):

* `is_category` - value `true`.
* `external_category_id` - value is category id of the Ecwid.

Every product is a [element](http://www.voog.com/developers/api/resources/elements). When product belongs to more than one category then it's stored once per category.

Expected [element definition for product element in Voog](http://www.voog.com/developers/api/resources/element_definitions) is:

* `external_id` (data_type: `string`) - product id in Ecwid.
* `external_category_id` (data_type: `string`) - product category id in Ecwid.
* `sku` (data_type: `string`) - product SKU in Ecwid.
* `price` (data_type: `string`) - product price in Ecwid.
* `description` (data_type: `text`) - product price in Ecwid.
* `options` (data_type: `text`) - product options in Ecwid.
* `combinations` (data_type: `text`) - product combinations in Ecwid.
* `image_url` (data_type: `string`) - product image url in Ecwid.
* `original_image_url` (data_type: `string`) - product original image url in Ecwid.

Product element definition can be created either manually or using [Voog Element definitions API](http://www.voog.com/developers/api/resources/element_definitions#create_element_definition):

```JSON
{
  "title": "Product",
  "fields": [
    {
      "key": "external_id",
      "title": "Product ID",
      "data_type": "string",
      "position": 1
    },
    {
      "key": "external_category_id",
      "title": "Category ID",
      "data_type": "string",
      "position": 2
    },
    {
      "key": "sku",
      "title": "SKU",
      "data_type": "string",
      "position": 3
    },
    {
      "key": "price",
      "title": "Price",
      "data_type": "string",
      "position": 4
    },
    {
      "key": "description",
      "title": "Description",
      "data_type": "text",
      "position": 5
    },
    {
      "key": "image_url",
      "title": "Product image url",
      "data_type": "string",
      "position": 6
    },
    {
      "key": "original_image_url",
      "title": "Product original image url",
      "data_type": "string",
      "position": 7
    },
    {
      "key": "options",
      "title": "Product options",
      "data_type": "text",
      "position": 8
    },
    {
      "key": "combinations",
      "title": "combinations",
      "data_type": "text",
      "position": 9
    }
  ]
}
```

## App configuration

App can be customized by using environmental variables. Check out configuration variable names in configuration files:

* [config/application.yml](./config/application.sample.yml) - defaults for application environment variables.
* [config/database.yml](./config/database.sample.yml) - database settings.

Minimum set of environmental variables for production environment:

* `EV_SYNC_ECWID_SHOP_ID="My eShop"`
* `EV_SYNC_ECWID_API3_ACCESS_TOKEN=ECWID_API_TOKEN` - ("scope":"read_store_profile create_orders read_catalog read_discount_coupons")
* `EV_SYNC_SECRET_KEY_BASE="long-random-string-3274y23472384y237842y73hwerbhjwfbjhsdbfsygf7r3gfsajdjd6"`
* `EV_SYNC_VOOG_HOST="my-store-page.voog.com"`
* `EV_SYNC_VOOG_API_TOKEN="VOOG-API-TOKEN"`
* `EV_SYNC_VOOG_PRODUCTS_LAYOUT_NAME="Products listing"`
* `EV_SYNC_VOOG_PRODUCTS_ELEMENT_DEFINITION="Products"`
* `EV_SYNC_VOOG_PRODUCTS_PARENT_PATH="en"`

To setup database configuration run `bin/setup` to instal gems and copy `config/database.sample.yml` to `config/database.yml` and `config/application.sample.yml` to `config/application.yml`.

### Get Voog API token

You have to generate your [Voog API token](http://www.voog.com/developers/api) from your profile settings page "Account" -> "My profile" (`http://yoursite.voog.com/admin/people/profile`).

Get or generate the API token and updated your `application.yml` file:

```
EV_SYNC_VOOG_API_TOKEN: "VOOG-API-TOKEN"
```

### Get Ecwid API v3 token

Request access to [Ecwid API v3](http://api.ecwid.com#register-your-app-in-ecwid). You need access to `read_catalog` scope.

Login to your Ecwid account.

**Step 1.** Go to  Ecwid's oAuth endpoint to get access authorize your app. Enter the url:

```
https://my.ecwid.com/api/oauth/authorize?client_id=MY-CLIENT-ID&redirect_uri=http%3A%2F%2Fwww.myshop.com%2Fapi&response_type=code&scope=read_catalog
```

**Step 2.** You are redirected to url specified in `redirect_uri` parameter. Grab the code form response url. Example:

```
http://www.myshop.com/api?code=SOME-RANDOM-CODE
```

**Step 3.** Retrieve access_token from Ecwid

```
curl "https://my.ecwid.com/api/oauth/token" \
-XPOST \
-d client_id=MY-CLIENT-ID \
-d client_secret=CLIENT-SECRET-KEY \
-d code=SOME-RANDOM-CODE \
-d redirect_uri=http%3A%2F%2Fwww.myshop.com%2Fapi \
-d grant_type=authorization_code
```

Example response:

```
{
  "access_token": "MY-APP-ACCESS-TOKEN-FOR-READ-CATALOG",
  "token_type": "Bearer",
  "scope":"read_store_profile read_catalog",
  "store_id": 11111
}
```

**Step 4.** Updated your `application.yml` file

```
EV_SYNC_ECWID_API3_ACCESS_TOKEN: "MY-APP-ACCESS-TOKEN-FOR-READ-CATALOG"
```


# Deploying application

Application has predefined [Capistrano](https://github.com/capistrano) tasks and some example scripts ([config/deploy/example_app.rb](./config/deploy/example_app.rb) and [config/deploy/example_app](./config/deploy/example_app)).

Add your deployment environment:

```
config
|--- deploy
|--- |--- my_shop_sync
|--- |--- |--- production.rb
|--- |--- my_shop_sync.rb
```

Add configuration for your environment (see example environment):

```
custom
|--- my_shop_sync
|--- |--- config
|--- |--- |--- application.yml
|--- |--- |--- database.yml
```

Check your server environment:

```
bundle exec cap my_shop:production check_write_permissions
```

Setup your custom configuration (see [example environment](./config/deploy/example_app.rb)):

```
bundle exec cap my_shop:production deploy:upload_configuration
```

Deploy your application:

```
bundle exec cap my_shop:production deploy
```

Deploy sript supports [RVM](https://rvm.io/) and [RBENV](https://github.com/sstephenson/rbenv) Ruby managers.
RBENV is used by default. When you use RVM in servers side, then you need to add additional environment variable to your deploy command:

```
CAP_USE_RVM=true bundle exec cap my_shop:production check_write_permissions
```

## Synchronization

Products and product categories are updated periodically using cron task. See details in (see [config/schedule.rb](./config/schedule.rb) file.

Products update check interval is 5 minutes, but products are updated only when something has been changed. Changes is detected by using cached information about last update and [Ecwid store update statistics endpoint](http://api.ecwid.com/#get-store-update-statistics).

Produt is synchronized only when it has been changed.

Once per day full synch is performed.

### Webhooks

This application supports also Ecwid webhooks to instantly synchronize updated and deleted products. Read more about how to [setup webhooks for Ecwid](http://api.ecwid.com/#what-is-webhook).
