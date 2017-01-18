### Deploying to Heroku

  This will deploy a fresh install of Sharetribe onto a Heroku server.

  * current as of Sharetribe v 6.0
  * apologies for my poor markdown skills
  * this is a [fork from svallory](https://gist.github.com/svallory/d08e9baa88e18d691605), including help from the comments

## You will need:

    - a [Heroku account](https://signup.heroku.com/)
    - a [local install of Sharetribe](https://github.com/sharetribe/)sharetribe/#installation) which you'll push your code from with Git
    - $ - it is not free to host on Heroku, and can run up around $100/month for a basic install very quickly.  Digital Ocean can be [much cheaper](http://bitbetter.se/moving-from-heroku-to-digitalocean/), but I haven't gotten around to [switching](https://www.digitalocean.com/community/tutorials/how-to-use-mysql-with-your-ruby-on-rails-application-on-ubuntu-14-04) yet!

  # Notes:

    - Sharetribe uses a MySQL database.  Rails standardly uses SQlite, and Heroku expects a PostgreSQL db.  So you'll need the cleardb Heroku addon to allow use of MySQL.

## Now the setup:    

  1. Install Heroku CLI + Login and create your app
    ```sh 
    heroku login
    heroku create YOUR_APP_NAME
    ```  

  2.  Generate your secret key for Heroku
    Generate secret key

    ```bash
    rake secret
    ```

    Add the following lines to `config/config.yml`:

    ```yml
    production:
      secret_key_base: # add here the generated key
    ```

  3. Choose other options you want to set in `config.yml` for production, such as mail_delivery_method - check out `config_defaults.yml` to see what options you can change. At a minimum, you must add secret_key_base: from previous step.

    ```sh  
    bundle exec rake heroku:config
    ```

  4. Configure the buildpacks Heroku will use to compile the app - Sharetribe relies on node (for building React component) and ruby (for Rails) - Node must come before Ruby

      ```sh
      heroku buildpacks:add heroku/nodejs
      heroku buildpacks:add heroku.ruby
      ```   

  5. Deploy git repo to Heroku (step 1 added Heroku as a git remote)

      ```sh
      git add .
      git commit -m 'off to deployment'
      git push heroku
      ```

    - You may get errors here.  I had to :

      - update bundler

        ```sh
        heroku run gem install bundler 
        ```
      - set specific version of NPM (Heroku didn't like Node 6.1 and NPM 3.10.9)
        add to `package.json` & `client/package.json` 

        ```json
          "engines": {
            "node": "6.1",
            "npm": "3.10.7"
          },
        ```
        to ensure that heroku uses the same version of NPM as local. 

        ```sh
        rm -rf client/node_modules
        npm install
        ```
      - ensure app is working as expected locally then re-deploy

    - Latest version of Sharetribe does not need the 'engines' to be specified as above, but that may come up again

  4. Install necessary addons for Heroku

    - (firstly remove postgresql)

      ```sh
      heroku addons:destroy heroku-postgresql
      ```
    - MemCachier (free)

      ```sh  
      heroku addons:create memcachier:dev
      ```
    - SSL ($20/mth) *only necessary [if you need to support < 1% of browsers](https://devcenter.heroku.com/articles/ssl#minimum-supported-browser-versions) that don't support SNI. Instead, just [upload your SSL cert](https://devcenter.heroku.com/articles/ssl) after deploy*

      ```sh
      heroku addons:create ssl:endpoint
      ```        
    - New Relic - with free package 'Wayne'

      ```sh  
      heroku addons:create newrelic:wayne
      ``` 
    - Flying Sphinx ($55/mth)

      ```sh 
      heroku addons:create flying_sphinx:ceramic
      ```
      > Ceramic plan is needed for Delta indexes. If you can manage without Delta Indexing, smaller plan is also ok
          
    - CLEARDB for mysql - this creates your MySQL DB that Heroku can talk to

      ```sh
      heroku addons:create cleardb:ignite
      ```

  5. Configure the Heroku addons 

    - New Relic - for monitoring /data

      `heroku addons:open newrelic`

       >  Copy the License key from the account settings.

       > Open `config/newrelic.yml` to set `license_key` variable value to your license.

    - CLEARDB - connnect to your database        

      - [Read about SSL setup](https://devcenter.heroku.com/articles/cleardb#using-ssl-with-cleardb-and-rails) and follow the steps below to get your SSL keys and database variable

    - Flying Sphinx - for site searching / indexing

      - Read and do the [instructions](https://devcenter.heroku.com/articles/flying_sphinx#configuration)

  6. And initialize your database
      
        `heroku run bundle exec rake db:structure:load`

      I could not get this to work on Sharetribe v6.0.

        Instead, I used Sequel Pro to connect to my local and ClearDB databases, and `mysqldump'd` the local, imported into the remote, with no problems
        Would love to hear if this worked out better for anyone else!

  7. Push local assets to Heroku (assuming you've been setting up your marketplace locally)

    - I changed my `.gitignore` file so that the `heroku push` would send the assets, and then re-deployed.

  8. Set up Amazon S3 to host your user-uploaded images, fonts, and admin-uploaded images via the Rails Asset Pipeline.

    - Follow Sharetribe instructions [here](https://github.com/sharetribe/sharetribe#setting-up-s3)

    - One bucket will allow users to upload images, and will delete them after the delayed jobs worker process them and stroes them into the other bucket.  

  9. On Upload bucket, choose 'Properties' -> 'Edit CORS Configuration' -> Insert Below

    ```xml
    <CORSConfiguration xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
      <CORSRule>
        <AllowedOrigin>*</AllowedOrigin>
        <AllowedMethod>GET</AllowedMethod>
        <AllowedMethod>POST</AllowedMethod>
        <AllowedMethod>PUT</AllowedMethod>
        <MaxAgeSeconds>50000</MaxAgeSeconds>
        <AllowedHeader>*</AllowedHeader>
      </CORSRule>
    </CORSConfiguration>
    ```

  9. Set up Amazon Cloudfront to deliver these assets via CDN

    - Create 2 distributions

    - Point one distribution to {your-app}.herokuapp.com // {yourdomain} (this will serve the application assets from the Rails asset pipeline via CDN)

    - Point other distribution to uploaded assets bucket (the one that does not expire), to serve uploaded assets.

    - I have struggled with [CORS](http://stackoverflow.com/questions/32592571/cloudfront-cors-issue-serving-fonts-on-rails-application) not allowing my icon fonts to load - I've had success but currently still having isues with this. Anyone have a solid fix please comment!

  11. Add Asset host variables to `config.yml` (in staging / production)

    ```yml
      s3_upload_bucket_name: "your-upload-bucket-name"
      s3_bucket_name: "your-assets-bucket-name"
      aws_access_key_id: "yourAwsAccessKeyId"
      aws_secret_access_key: "yourAwsSecretKey"
      asset_host: 'appAssetsDistribution.cloudfront.net'
      user_asset_host: 'uploadedAssetsDistribution.cloudfront.net'  
    ```
      ensure to run `bundle exec rake heroku:config` each time you edit this file to send the variables to Heroku

  10. Turn on dynos in Heroku

    - The procfile should have setup two dynos in Heroku, make sure to switch them on in your Heroku admin.

    - I also had to change '$PASSENGER_MAX...' to '3' in my procfile to deploy.

  11. Run the sphinx index + start daemon

    ```sh
    heroku run bundle exec rake fs:index
    heroku run bundle exec rake fs:start
    ```
        
  12. You can now put in the scheduler addon to run background jobs.

          heroku addons:create scheduler:standard
          
      Open the scheduler
      
        heroku addons:open scheduler

      And add the following jobs:

        - bundle exec rake fs:index
          - frequency: 10 mins
        - rails runner "CommunityMailer.deliver_community_updates"
          - frequency: daily
        - bundle exec rake sharetribe:delete_expired_auth_tokens
          - frequency: daily

  13. Updates
    
    Follow [this](https://www.sharetribe.com/community/t/best-way-to-upgrade-sharetribe-with-the-latest-release/227/6)

          
## [To set up a staging site](https://devcenter.heroku.com/articles/multiple-environments#starting-from-an-existing-app)

  - Change git remote name to production, and fork it to staging 

  ```sh
  git remote rename heroku production
  heroku fork --from production --to staging
  git remote add staging https://git.heroku.com/integration.git
  ```
          
## Recomended dyno sizes

    Production:
      - **web:** Standard-2X
      - **worker:** Standard-2X

    Staging:
      - Same, but free use 2 free dynos


