# I'm in the fast lane

We recommend at least reading through [Preperation](#preperation) first. Once you're ready, bringing up the containers is easy.

Here's what it looks like on a Mac:
```
git clone git@github.com:this/repo.git && cd /Users/$(whoami)/repos/atlassian
docker build -t nginx_with_config . && docker-compose up
```

## Atlassian services

    Version: 1.1.0

This repository holds a dockerized orchestration of the Atlassian web apps
Jira, Stash and Confluence. To simplify the usermangement Crowd is also
included. For more information on the apps please refere to the offical
Atlassian websites:

- [Jira][1]
- [Stash][2]
- [Confluence][3]
- [Crowd][4]
- [Bamboo][5]

### Prerequisites

In order to run this apps you need to make sure you're running at least
[docker 1.6.0][6] and [docker-compose 1.2.0][7]. For detailed installation
instructions please refere to the origin websites:

  - [https://docs.docker.com/installation][8]
  - [https://docs.docker.com/compose][9]

### Preperation

There are two ways you might be running Docker:

- Linux Docker Host -> Container (L->C)
- Workstation (Mac/Windows) -> Linux Docker Host -> Container (W->L->C)

The following instructions will assume you're using a Workstation (Mac) with a Linux Docker Host (managed by Virtualbox VM).

**Shared Folders**
On Mac `/Users` is shared by default, so a great place to clone this repo is `/Users/$(whoami)/repos/atlassian`. This is important to ensure that shares folders are visable through all three levels W->L->C

**Updating resources on your Docker Host**

WARNING: This will make changes to your docker host, so consider other containers you may be running. Also consider if your workstation has enough resources to support these changes.

```
# variables
DOCKER_HOST_VM_NAME=default
DOCKER_HOST_IP=$(docker-machine ip ${DOCKER_HOST_VM_NAME})
MEMORY=5120
CPUs=4

# Update your docker host VM to have enough resources for the entire stack.
VBoxManage controlvm ${DOCKER_HOST_VM_NAME} poweroff
VBoxManage modifyvm  ${DOCKER_HOST_VM_NAME} --memory ${MEMORY}
VBoxManage modifyvm  ${DOCKER_HOST_VM_NAME} --cpus ${CPUs}
VBoxManage startvm   ${DOCKER_HOST_VM_NAME} --type headless
```

**Making sure your containers are addressable**

You'll want to access your containers from your browser. To acheive this you should update your hosts file to point to your Docker Host.

```
# variables
DOCKER_HOST_VM_NAME=default
DOCKER_HOST_IP=$(docker-machine ip ${DOCKER_HOST_VM_NAME})

# make sure your containers have addressable hostnames
cat <<EOF | sudo tee -a /etc/hosts > /dev/null
${DOCKER_HOST_IP} crowd.docker stash.docker bamboo.docker jira.docker confluence.docker
EOF

# make sure you forward port 80 from W->L
PORT_FROM=80
PORT_TO=80
VBoxManage controlvm ${DOCKER_HOST_VM_NAME} natpf1 "port${PORT_FROM}_${PORT_TO},tcp,127.0.0.1,${PORT_FROM},,${PORT_TO}"
```

Now you'll be able to browse addresses like http://crowd.docker from your browser.

### Start the images

You can start all images as a orchestration from the root folder. To
only use a particular image change into a subfolder. You better use
the `docker-compose-dev.yml` file if you're not in production. Here
are some examples:

    # build all the images
    $ docker-compose build

    # build only the stash image
    $ cd atlassian-stash && docker-compose build

    # start all the docker images (in development mode)
    $ docker-compose -f docker-compose-dev.yml dev

    # start the stash image (in production mode)
    $ cd atlassian-stash && docker-compose -f docker-compose-dev.yml up

    # inspect the logs
    $ docker-compose logs

If you deploy the apps for the first time you may need to restore the
databases from a backup and adapt the database connection settings!

### Develop Mode / Debug an image

    # use the development compose file
    $ docker-compose -f docker-compose-dev.yml up

    # execute a bash shell inside a running container
    $ docker exec -it atlassian_stash_1 bash

    # add the following entrys to your `/etc/hosts`
    $ boot2docker ip -> 192.168.59.103
    $ cat /etc/hosts
    192.168.59.103  boot2docker.local boot2docker
    192.168.59.103  stash.boot2docker.local stash
    192.168.59.103  jira.boot2docker.local jira
    192.168.59.103  confluence.boot2docker.local confluence
    192.168.59.103  crowd.boot2docker.local crowd
    192.168.59.103  bamboo.boot2docker.local bamboo

### First run

If you start this orchestration for the first time, a handy feature is to
import your old data. If you're e.g. moving everything to another server
you can put your database backups into the tmp folder and the db initscript
will pick them up automagically on the first run.

    # move your jira db backup file to tmp (filename is important).
    $ mv jira_backup.sql tmp/jira.dump

    # unpack your jira-home backup archive
    $ tar xzf jira-home.tar.gz --strip=1 -C atlassian-jira/home

### Backup the home folders

    $ mkdir -p backup/$(date +%F)
    $ for i in crowd confluence stash jira bamboo; do \
      tar czf backup/$(date +%F)/$i-home.tgz atlassian-$i/home; done

### Backup the PostgreSQL data

    # backup the confluence database
    $ docker run -it --rm --link atlassian_database_1:db -v $(pwd)/tmp:/tmp \
        postgres sh -c 'pg_dump -U confluence -h "$DB_PORT_5432_TCP_ADDR" \
        -w confluence > /tmp/confluence.dump'

    # backup the stash database
    $ docker run -it --rm --link atlassian_database_1:db -v $(pwd)/tmp:/tmp \
        postgres sh -c 'pg_dump -U stash -h "$DB_PORT_5432_TCP_ADDR" \
        -w stash > /tmp/stash.dump'

    # backup the jira database
    $ docker run -it --rm --link atlassian_database_1:db -v $(pwd)/tmp:/tmp \
        postgres sh -c 'pg_dump -U jira -h "$DB_PORT_5432_TCP_ADDR" \
        -w jira > /tmp/jira.dump'

    # backup the crowd database
    $ docker run -it --rm --link atlassian_database_1:db -v $(pwd)/tmp:/tmp \
        postgres sh -c 'pg_dump -U crowd -h "$DB_PORT_5432_TCP_ADDR" \
        -w crowd > /tmp/crowd.dump'

    # backup the bamboo database
    $ docker run -it --rm --link atlassian_database_1:db -v $(pwd)/tmp:/tmp \
        postgres sh -c 'pg_dump -U bamboo -h "$DB_PORT_5432_TCP_ADDR" \
        -w bamboo > /tmp/bamboo.dump'

### Restore the PostgreSQL data

    # restore the confluence database backup
    $ docker run -it --rm --link atlassian_database_1:db -v $(pwd)/tmp:/tmp \
        postgres sh -c 'pg_restore -U confluence -h "$DB_PORT_5432_TCP_ADDR" \
        -n public -w -d confluence /tmp/confluence.dump'

    # restore the stash database backup
    $ docker run -it --rm --link atlassian_database_1:db -v $(pwd)/tmp:/tmp \
        postgres sh -c 'pg_restore -U stash -h "$DB_PORT_5432_TCP_ADDR" \
        -n public -w -d stash /tmp/stash.dump'

    # restore the jira database backup
    $ docker run -it --rm --link atlassian_database_1:db -v $(pwd)/tmp:/tmp \
        postgres sh -c 'pg_restore -U jira -h "$DB_PORT_5432_TCP_ADDR" \
        -n public -w -d jira /tmp/jira.dump'

    # restore the crowd database backup
    $ docker run -it --rm --link atlassian_database_1:db -v $(pwd)/tmp:/tmp \
        postgres sh -c 'pg_restore -U crowd -h "$DB_PORT_5432_TCP_ADDR" \
        -n public -w -d crowd /tmp/crowd.dump'

    # restore the bamboo database backup
    $ docker run -it --rm --link atlassian_database_1:db -v $(pwd)/tmp:/tmp \
        postgres sh -c 'pg_restore -U bamboo -h "$DB_PORT_5432_TCP_ADDR" \
        -n public -w -d bamboo /tmp/bamboo.dump'

---
[1]: https://www.atlassian.com/software/jira
[2]: https://www.atlassian.com/software/stash
[3]: https://www.atlassian.com/software/confluence
[4]: https://www.atlassian.com/software/crowd
[5]: https://www.atlassian.com/software/bamboo
[6]: https://docker.com
[7]: https://docs.docker.com/compose
[8]: https://docs.docker.com/installation
[9]: https://docs.docker.com/compose/#installation-and-set-up
