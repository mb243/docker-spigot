#!/bin/bash

#
# This file is placed on the Minecraft volume and kicked off when the container
# is started. Feel free to modify this file within your Docker volume.
#

write_eula() {
    if [[ "$EULA" == "true" ]]; then
      echo "# Generated via Docker on $(date)" > /minecraft/eula.txt
      echo "eula=true" >> /minecraft/eula.txt
    else
      echo "--------------------------------------------------------------"
      echo "In order to run Spigot, you must read and accept Mojang's EULA"
      echo "posted at  https://account.mojang.com/documents/minecraft_eula"
      echo "If you agree, add this to the docker run command: -e EULA=true"
      echo "--------------------------------------------------------------"
      exit 1
    fi
}

build_spigot_jar() {
  # only build if jar file does not exist
  if [ ! -f /minecraft/spigot.jar ]; then
    echo "Building spigot jar file, this will take a few minutes..."
    mkdir -p /minecraft/build && cd /minecraft/build
    curl -o BuildTools.jar -L \
      https://hub.spigotmc.org/jenkins/job/BuildTools/lastSuccessfulBuild/artifact/target/BuildTools.jar
    java -jar BuildTools.jar --rev ${REV}
    cp /minecraft/build/spigot-*.jar /minecraft/spigot.jar
    ls -l /minecraft/spigot.jar
  fi
}

run_spigot() {
  # change owner to minecraft
  sudo chown -R minecraft:minecraft /minecraft/
  cd /minecraft/
  exec /usr/bin/java ${JVM_OPTS} -jar /minecraft/spigot.jar
}

main() {
  write_eula
  build_spigot_jar
  run_spigot
}

main
