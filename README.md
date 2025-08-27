# Mybooking - Interview test

## Prerequesites

- Ruby 3.3.0
- MySQL or MariaDB

## Database

The file prueba_tecnica.sql is a dump of the db to be used.

## Preparing the environment
```
bundle install
````

Create an .env file at project root with the following variables

```ruby
COOKIE_SECRET="THE-COOKIE-SECRET"
DATABASE_URL="mysql://user:password@host:port/prueba_tecnica?encoding=UTF-8-MB4"
TEST_DATABASE_URL="mysql://user:password@host:port/prueba_tecnica_test?encoding=UTF-8-MB4"
```
## Running with Docker
For up the Dbs in docker
```
docker-compose up -d
```

## Running the application

```
bundle exec rackup
```

Then, you can open the browser and check

http://localhost:9292
http://localhost:9292/api/sample

## Running tests

The project uses rspec as testing library

````
bundle exec rspec spec
````

## Working with Rake for command line utils

A basic task, foo:bar, has been implemented to show how it works

```
bundle exec rake foo:bar
```

## Details

This is a sample application for Mybooking technical interview. 
It's a Ruby Sinatra webapp that uses bootstrap 5.0 as the css framework.

## Debugging

Install the extension rdbg and use this as lauch.json

````
{
    // Use IntelliSense para saber los atributos posibles.
    // Mantenga el puntero para ver las descripciones de los existentes atributos.
    // Para más información, visite: https://go.microsoft.com/fwlink/?linkid=830387
    "version": "0.2.0",
    "configurations": [
        {
            "type": "rdbg", // "rdbg" is the type of the debugger
            "name": "Debug Ruby Sinatra",
            "request": "attach",
            "debugPort": "1235",  // The same port as in the config.ru file
            "localfs": true       // To be able to debug the local files using breakpoints
        }
    ]
}
````

