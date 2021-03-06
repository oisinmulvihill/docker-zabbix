Docker Zabbix
========================

## Oisin's Changes

A slight interruption is needed...

I've created a "/logs" directory you can use from your externalscripts and other
scripts to aid development and debugging them. To have access on the host machine
you would need to use the -v option e.g. -v /tmp:/logs.

The zabbix server and agent on docker will now put their logs in /logs directory
which helps debugging.

### my quick build and run reference

#### Build

I build this docker image locally (from the checkout directory):

```
    sudo docker build -t oisinmulvihill/docker-zabbix .
```

#### Set up mount points

This is once off set up on my vagrant box. I'm using my own set up for this.

E.g. docker box from https://github.com/oisinmulvihill/handy-setups

```

    sudo mkdir -p /var/lib/zabbix/mysql
    sudo mkdir -p /var/lib/zabbix/alertscripts
    sudo mkdir -p /var/lib/zabbix/externalscripts
    sudo mkdir -p /var/lib/zabbix/zabbix_agentd.d
    sudo mkdir -p /var/lib/zabbix/logs

    sudo chown -R vagrant: /var/lib/zabbix

```

#### Run interactively

I forward the ports and mount the volumes for testing purposes as:

```

    sudo docker run -i -t \
        -v /var/lib/zabbix/mysql:/var/lib/mysql \
        -v /var/lib/zabbix/alertscripts:/usr/lib/zabbix/alertscripts \
        -v /var/lib/zabbix/externalscripts:/usr/lib/zabbix/externalscripts \
        -v /var/lib/zabbix/logs:/logs \
        -v /etc/zabbix/zabbix_agentd.d:/etc/zabbix/zabbix_agentd.d \
        -p 10051:10051 \
        -p 10052:10052 \
        -p 2080:80 \
        -p 2022:22 \
        -p 2812:2812 \
        oisinmulvihill/zabbix

```

My version of this is available on the docker repository here
* https://registry.hub.docker.com/u/oisinmulvihill/docker-zabbix/

And now, back to your normal program...

## Container

The container provides the following *Zabbix Services*, please refer to the [Zabbix documentation](http://www.zabbix.com/) for additional info.

* A *Zabbix Server* at port 10051.
* A *Zabbix Java Gateway* at port 10052.
* A *Zabbix Web UI* at port 80 (e.g. `http://$container_ip/zabbix` )
* A *Zabbix Agent*.
* A MySQL instance supporting *Zabbix*, user is `zabbix` and password is `zabbix`.
* A Monit deamon managing the processes (http://$container_ip:2812, user 'myuser' and password 'mypassword').

## Usage

You can run Zabbix as a service executing the following command.

```
docker run -d \
           -p 10051:10051 \
           -p 10052:10052 \
           -p 80:80       \
           -p 2812:2812   \
           berngp/docker-zabbix
```

The above command will expose the *Zabbix Server* through port *10051* and the *Web UI* through port *80* on the host instance, among others.
Be patient, it takes a minute or two to configure the MySQL instance and start the proper services. You can tail the logs using `docker logs -f $contaienr_id`.

After the container is ready the *Zabbix Web UI* should be available at `http://$container_ip/zabbix`. User is `admin` and password is `zabbix`.

# Developers

## Setting your Docker environment with the Vagrantfile

To run the included _Vagrantfile_ you will need [VirtualBox](https://www.virtualbox.org/) and [Vagrant](http://www.vagrantup.com/) installed. Currently I am testing it against _VirtualBox_ 4.3.6 and _Vagrant_ 1.4.1. The _Vagrantfile_ uses a minimal _Ubuntu Precise 64_ box and installs the _VirtualBox Guest Additions_ along with _Docker_ and its dependencies. The first time you execute a `vagrant up` it will go through an installation and build process, after its done you will have to execute a `vagrant reload`. After that you should be able to do a `vagrant ssh` and find that _Docker_ is available using a `which docker` command.

*Be aware* that the _Vagrantfile_ depends on the version of _VirtualBox_ and may run into problems if you don't have the latest versions.

Once your _Vagrant_ instance is up you should be able to ssh in (`vagrant ssh`) and have the `docker` command available. By default _Docker_ is also started as a service/daemon.

## Building the Docker Zabbix Repository.

Within an environment that is already running _Docker_, such as the _VirtualBox_ instance described above, checkout the *docker-zabbix* code to a known directory. If you are using the _Vagrantfile_ it will be available by default in the `/docker/docker-zabbix` directory. From there you can execute a build and run the container.

e.g.

```
# CD into the docker container code.
cd /docker/docker-zabbix
# Build the contaienr code.
docker build -t berngp/docker-zabbix .
# Run it!
docker run -i -t \
        -p 10051:10051 \
        -p 10052:10052 \
        -p 80:80       \
        -p 2812:2812    \
        berngp/docker-zabbix
```

## Exploring the Docker Zabbix Container

Sometimes you might just want to review how things are deployed inside the container. You can do that by bootstrapping the container and jumping into a _bash shell_.
Execute the command bellow to do it.

```
docker run -i -t -p 10051 \
                 -p 10052 \
                 -p 80    \
                 -p 2812  \
                 --entrypoint="" berngp/docker-zabbix /bin/bash
```

Note that in the example above we are telling _docker_ to bind ports 10051, 10052, 80 and 2812 but we are not giving explicit mapping of those ports. You will have to run `docker ps` to figure out the port mappings in relationship with the host.


Happy metrics gathering!
