# Pajitnov

This is a tetromino stacking game server and visualization that can be played
by 2-4 bots.

In the server folder, you'll find the backend implementation, which uses our
gameworks framework gem.  See /public/api/index.html for more information on
interacting with the server.

In the client folder, you'll find the visualization, written in javascript with
react.  It uses WebSockets to listen for changes pushed out by the server, and
animates the game accordingly.

## Development Environment

The dev environment is set up to be easy to use with docker. Just run the
following commands:

```bash
docker-compose build
docker-compose run --rm web bundle install
docker-compose run --rm client npm install
docker-compose up
```

This starts up a client and a server container. If you're using
[Dinghy](https://github.com/codekitchen/dinghy) (which you totally should be if
you're on OS X), the server will be available at `pajitnov.docker` and the
client will be available at `pajitnov-client.docker`.

If you aren't using dinghy, you'll have to modify docker-compose.yml to point
the client's PANDA_PUSH_BASE_URL to the pandapush container and port, since
you'll need to be able to hit that URL from your web browser outside of the
containers. For instance if `docker-compose port pandapush 3000` reports
`0.0.0.0:32777`, you'll need to set PANDA_PUSH_BASE_URL to
`http://127.0.0.1:32777` if docker is running on your host, or
`http://<vm_ip>:32777` if docker is running in a VM.

## Bots

Check out our sample bots in the `bots/` folder and write your own!
