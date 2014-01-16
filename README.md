# Proletariat: Background Workers Unite!

Lightweight background processing in Ruby powered by RabbitMQ and the excellent concurrent-ruby gem.

[![Code Climate](https://codeclimate.com/repos/52d75c166956805abe000226/badges/bf98213c1d629072560c/gpa.png)](https://codeclimate.com/repos/52d75c166956805abe000226/feed)

### Warning!

This software is early-alpha, may contain bugs and change considerably in the near future.

For production use I recommend the better supported and more fully-featured [Sneakers gem](https://github.com/jondot/sneakers).

## Installation

Add this line to your application's `Gemfile`:

    gem 'proletariat'

And run:

    $ bundle

## How to use

### RabbitMQ connection config

If you aren't using default RabbitMQ connection settings, ensure the `RABBITMQ_URL` env variable is present. Here's how that might look in your `.env` if you use Foreman:

	RABBITMQ_URL=amqp://someuser:somepass@127.0.0.1/another_vhost

### Setting up a Worker

Your worker classes should inherit from `Proletariat::Worker` and implement the `#work` method.

Proletariat works exclusively on RabbitMQ Topic exchanges and routing keys can be bound via a call to `.listen_on`. This can be called multiple times to bind to multiple keys.

The `#work` method should return `:ok` on success or `:drop` / `:requeue` on failure.

Here's a complete example:
	
	class SendUserIntroductoryEmail < Proletariat::Worker
	  listen_on 'user.created'
	
	  def work(message)
	    params = JSON.parse(message)
	
	    UserMailer.introductory_email(params).deliver!
	
	    publish 'email_sent.user.introductory', {id: params['id']}.to_json
	
	    :ok
	  end
	end
	
### Select your Workers

If you are using Rails just create a `proletariat.rb` file in your initializers directory.

	Proletariat.configure worker_classes: [SendUserIntroductoryEmail, SomeOtherWorker]
	Proletariat.run!
	
Or define the `WORKERS` env variable.

	WORKERS=SendUserIntroductoryEmail,SomeOtherWorker
	
### Testing with Cucumber

Add the following to your `env.rb`:

	require 'proletariat/cucumber'
	
Use the provided helpers in your step definitions to synchronize your test suite with your workers without sacrificing the ability to test in production-like environment:

	When(/^I submit a valid 'register user' form$/) do
	  wait_for message.on_topic('email_sent.user.introductory') do
	    visit   ...
	    fill_in ...
	    submit  ...
	  end
	end
	
	Then(/^the user should receive an introductory email$/) do
	  expect(unread_emails_for(new_user_email).size).to eq 1
	end

## FAQ

#### Why build another RabbitMQ background worker library?

I wanted a library which shared one RabbitMQ connection across all of the workers on a given process. Many hosted RabbitMQ platforms tightly limit the max number of connections.

## TODO
- Improve test suite :(
- Add command line interface
- Abstract retry strategies