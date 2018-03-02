# Docker Spigot

Docker image to build a Spigot server
See <https://hub.docker.com/r/mb101/docker-spigot> for the Docker Hub image.

## About this image

This container will set up a Minecraft server running the Spigot software.

The first time you start this container, it will download and build the Spigot jar file using [Spigot BuildTools](https://www.spigotmc.org/wiki/buildtools/). This can take 5-10 minutes or more, depending on the speed of your system. After this, the server will automatically start. Subsequent `start`s will use the downloaded jar file instead of compiling a new one.

If you wish to get a new `spigot.jar` file, simply stop the container and delete the `spigot.jar` file from the volume. At the next boot, BuildTools will be downloaded and a new `spigot.jar` file will be compiled.

## Building

You will need the image in order to run this server. You can either build it from GitHub, or pull it from Docker Hub.

### Pulling from Docker Hub

This is the preferred way, and is done automatically. You can skip the "Building from GitHub" section below unless you're unable to pull from Docker Hub and need to build it manually.

### Building from GitHub

```
git clone git@github.com:mb243/docker-spigot.git
cd docker-spigot
docker build -t mb101/docker-spigot images/ubuntu
```

_The build step may take 2-3 minutes or more, depending on the speed of your internet connection and system_

## Running

The following is an example command to run this Docker image:

```
docker run --name spigot --restart unless-stopped -e "JVM_OPTS=-Xmx4096M" -p 25565:25565 -itd mb101/docker-spigot
```

If you want to expose additional ports for services like DynMap's built-in webserver, Votifier, etc., you can do this with one or more combinations of the `--expose` and `-p` flags. Here is one example using port 8192 for Votifier:

```
docker run --name spigot --restart unless-stopped -e "JVM_OPTS=-Xmx4096M" --expose=8192 -p 8192:8192 -p 25565:25565 -itd mb101/docker-spigot
```

You can also set the RAM used by Spigot to another amount by changing the value after `-Xmx`.

**NOTE**: You must specify your agreement with [Mojang's EULA](https://account.mojang.com/documents/minecraft_eula) by passing `-e EULA=true` to `docker run`.

## Stopping

Stop the server by running `docker stop`. By default, Docker only allows 10 seconds for PID 1 to exit. Depending on the number of players or plugins that you have, Spigot may take a bit longer, and extending this through the use of `-t` or `--time` is encouraged. For example:

```
docker stop -t 15 spigot
```

This allows 15 seconds to stop.

## Accessing the container

There are two ways to access the container: Through a shell, or by attaching directly to the running console.

You can also access the container volume to edit files or add plugins.

### Accessing the container through a shell

```
docker exec -it spigot bash
```

### Attaching to the Spigot console

To connect to it to run console commands or view logs in realtime, run the following:

```
docker attach spigot
```

**If you press ctrl-c on the console, the server will stop.** To detach properly, press **ctrp-p, ctrl-q**.

## Accessing the volume

You can access the volume like any other directory. First, you have to find it.

### Finding the volume by inspecting the container

`docker inspect spigot | grep -i '"Type": "volume"' -A3`

You want the container name. The remainder of the data fields are only for reference.

### Finding the volume by searching the disk

If you deleted the container, the container itself is gone but the volume still exists (unless you used `docker rm -v`). Since `spigot.jar` lives in the volume, you can find it with the following:

`find /var/lib/docker/volumes -name spigot.jar | xargs ls -l`

Once you've found it, create a new container and mount it:

```
docker run --name spigot --restart unless-stopped -p 25565:25565 \
  --mount type=volume,source=cc908d746d3275d6d495bff0d68b1f89d602aa23e2738a865edb49d59ecb0756,destination=/minecraft \
  -tid mb101/docker-spigot
```

Substitute the volume name that you discovered previously.

## Installing plugins

-   Stop the container (`docker stop spigot`)
-   Drop any plugins in the `plugins/` directory on the volume
-   Start the container (`docker start spigot`)

## Setting up a static IP

If you have a separate MySQL container that you use for storing plugin data, you will want it to be on a static IP to prevent the IP address from changing if you later add or remove containers.

The best way to do this is via `docker network`. If you have not already, add a network and connect your MySQL container and your Spigot container to it. The following are example commands, and you must modify them for your own environment:

```
docker network create --subnet=172.36.0.0/16 my_network
docker network connect --ip=172.36.0.2 my_network mysql
docker network connect --ip=172.36.0.3 my_network spigot
```

# Technical information about this image

`start.sh` is set as the ENTRYPOINT in the Dockerfile. `start.sh` will `exec` java to make it PID 1, which allows it to receive SIGTERM from Docker and shut down gracefully whenever possible.

`start.sh` lives on the volume. You can edit it to run additional commands at startup. If you break it, simply delete it and deploy a new container, and it will be replaced with the version from the image. Or, just replace it with [this one](https://github.com/mb243/docker-spigot/blob/master/images/ubuntu/minecraft/start.sh).
