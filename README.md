# Spigot

Docker image to build a Spigot server
See <https://hub.docker.com/r/mb101/docker-spigot>

# About this image

The first time you start this container, it will download and build the Spigot jar file using [Spigot BuildTools](https://www.spigotmc.org/wiki/buildtools/). This can take between 7-10 minutes or more, depending on the speed of your system. After this, the server will automatically start.

`start.sh` is set as the ENTRYPOINT in the Dockerfile. `start.sh` will `exec` java to make it PID 1, which allows it to recieve SIGTERM from Docker and shut down gracefully whenever possible.

# Building and running

## Building

Build with:

```
docker build -t spigot images/ubuntu
```

## Running

Run with:

```
docker run --name mcserver --restart unless-stopped -e "JVM_OPTS=-Xmx4096M" -p 25565:25565 -itd spigot
```

If you want to expose additional ports for services like DynMap's built-in webserver, Votifier, etc., you can do this with one or more combinations of the `--expose` and `-p` flags. Here is one example using port 8192 for Votifier:

```
docker run --name mcserver --restart unless-stopped -e "JVM_OPTS=-Xmx4096M" --expose=8192 -p 8192:8192 -p 25565:25565 -itd spigot
```

**NOTE**: You must specify your agreement with [Mojang's EULA](https://account.mojang.com/documents/minecraft_eula) by passing `-e EULA=true` to `docker run`. To prevent copypasta, this is not provided in any examples.

## Stopping

By default, Docker only allows 10 seconds for PID 1 to exit. Spigot may take a bit longer, and extending this through the use of `--time` is encouraged:

```
docker stop -t 15 mcserver
```

## Networking with a MySQL container

If you have a separate MySQL container that you use for storing plugin data, you will want it to be on a static IP to prevent the IP address from changing if you later add or remove containers.

The best way to do this is via `docker network`. If you have not already, add a network and connect your MySQL container and your Spigot container to it. The following are example commands, and you must modify them for your own environment:

```
docker network create --subnet=172.36.0.0/16 my_network
docker network connect --ip=172.36.0.2 my_network mysql
docker network connect --ip=172.36.0.3 my_network mcserver
```

# Accessing the container through a shell

`docker exec -it mcserver bash`

# Accessing the Spigot console

To connect to it to run console commands or view logs in realtime, run the following:

```
docker attach mcserver
```

To detach, press **ctrp-p, ctrl-q**

# Finding the volume

`docker inspect mcserver | grep -i '"Type": "volume"' -A3`

You want the container name. The remainder of the data fields are only for reference.

## Recovering the volume

The Minecraft server files and associated world data are stored in a Docker volume. If you delete the container, this data will still persist and can be attached to a new container, but you have to know what volume the data lives in.

### If the container still exists

If the container still exists, you can run the above command to get the volume info.

### If you deleted the container

Since `spigot.jar` lives in the volume, you can find it with the following:

`find /var/lib/docker/volumes -name spigot.jar | xargs ls -l`

Once you've found it, create a new container and mount it:

```
docker run --name mcserver --restart unless-stopped -p 25565:25565 \
  --mount type=volume,source=cc908d746d3275d6d495bff0d68b1f89d602aa23e2738a865edb49d59ecb0756,destination=/minecraft \
  -t -d spigot
```

Substitute the volume name that you discovered previously.

# Installing plugins

-   Stop the container (`docker stop mcserver`)
-   Drop any plugins in the `plugins/` directory on the volume
-   Start the container (`docker start mcserver`)

# Talking to another container

MySQL in container? Need a static IP?

```
docker network create --subnet=172.24.0.0/16 docker_net
docker network connect --ip=172.24.0.4 docker_net  mysql
docker network connect --ip=172.24.0.1 docker_net  mcserver
```
