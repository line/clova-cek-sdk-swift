# Clova-CEK-SDK-Swift

## About this repository

This is a library to help for development of the extension with the Clova Extension Kit (CEK).
CEK Documentation can be found [here](https://clova-developers.line.me/guide/).

This library also contains a sample project which returns local time of a city in the world about which an user asks Clova.

## Architecture

This library and the sample project can be built with the Swift Package Manager(SPM). It has a dependency on Kitura.

Following environment variables need to be set when it runs:

### For the sample project
|Name|Value|Explanation|is Mandatory|
| --- | --- | --- | --- |
|PORT|Int|A port number to listen to|Yes (Heroku automatically sets it)|
|APPLICATION_ID|String|An application Id that you set on the clova platform|Eiter this or PATH_FOR_DEBUG is necessary|
|PATH_FOR_DEBUG|Any|If set, the server responds in <PATH_FOR_DEBUG> without verification|Eiter this or APPLICATION_ID is necessary|
|LOG_TYPES|String|Log types to output. Combine following strings with `,`: `ENTRY`, `EXIT`, `DEBUG`, `VERBOSE`, `INFO`, `WARNING`, `ERROR`|No|
|GOOGLE_API_KEY|String|A user key for Google Geocoding API|No|

## Preparation of development

To develop it with XCode, do
```
$ swift package generate-xcodeproj --xcconfig-overrides settings.xcconfig
$ open *.xcodeproj
```

It has a Dockerfile which can be used by Docker. If you want to use Docker for build, execusion or deploy, install Docker.
https://docs.docker.com/docker-for-mac/

## Preparation in the Clova Platform for the sample app

This sample app handles an intent named `CityTimeIntent`, with a slot named `city_name`.
Log into the platform and register them in your skill with enough number of corpora.

## Build the sample app

SPM
```
$ swift build
```

Docker
```
$ docker-compose build web
```

## Run the sample app

SPM(Hit Control+C to quit)
```
$ swift run
```

Docker(Hit Control+C to quit)
```
$ docker-compose up web
```

## Deploy to Heroku with Docker

The webhook server for the extension requires SSL connection and we introduce Heroku as one of the solution.

### Preparation

Make sure Docker is running
```
$ docker ps
```

Install Heroku-CLI. Brew can be used:
```
$ brew install heroku/brew/heroku
```

Create your Heroku account.
https://www.heroku.com

Log into Heroku and create your app.
With heroku commands after here, you can specify existing app name by putting --apps <app name>.
```
heroku login
heroku create
```

### Environment variables

Set necessary environment variables besides $PORT which is automatically set by Heroku.
```
$ heroku config:add LOG_TYPES="WARNING,ERROR"
```

Set PATH_FOR_DEBUG to answer any request without verification
```
$ heroku config:add PATH_FOR_DEBUG="/debug"
```

### Deploy

```
$ heroku container:login
$ heroku container:push web
$ heroku container:release web
```

## References

How to run Vapor with Docker in Heroku
https://gist.github.com/alexaubry/bea6f9b626e71b48ae6065664748bc97

Container Registry & Runtime (Docker Deploys)
https://devcenter.heroku.com/articles/container-registry-and-runtime
