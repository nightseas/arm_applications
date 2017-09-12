# Run Docker on ClearFog Base
---
Well since I find out Armbian is a docker-ready host system, there's not much to say about installing docker. Just copy the official docker installation guide and make some correction.

My test environment:

 - ClearFog Base + A388 SoM (with 8GB eMMC)
 - Armbian 5.32 Ubuntu Xenial Image
---

## Uninstall old versions

Older versions of Docker were called `docker` or `docker-engine`. If these are
installed, uninstall them:

```bash
$ sudo apt-get remove docker docker-engine docker.io
```

## Install Docker CE using the repository

Before you install Docker CE for the first time on a new host machine, you need to
set up the Docker repository. Afterward, you can install and update Docker from
the repository.

### Set up the repository

1.  Update the `apt` package index:

    ```bash
    $ sudo apt-get update
    ```

2.  Install packages to allow `apt` to use a repository over HTTPS:

    ```bash
    $ sudo apt-get install \
        apt-transport-https \
        ca-certificates \
        curl \
        software-properties-common
    ```

3.  Add Docker's official GPG key:

    ```bash
    $ curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    ```

    Verify that the key fingerprint is `9DC8 5822 9FC7 DD38 854A  E2D8 8D81 803C 0EBF CD88`.

    ```bash
    $ sudo apt-key fingerprint 0EBFCD88

    pub   4096R/0EBFCD88 2017-02-22
          Key fingerprint = 9DC8 5822 9FC7 DD38 854A  E2D8 8D81 803C 0EBF CD88
    uid                  Docker Release (CE deb) <docker@docker.com>
    sub   4096R/F273FCD8 2017-02-22
    ```

4.  Use the following command to set up the **stable** repository for **armhf**:

    ```bash
    $ sudo add-apt-repository \
       "deb [arch=armhf] https://download.docker.com/linux/ubuntu \
       $(lsb_release -cs) \
       stable"
    ```

### Install Docker CE

1.  Update the `apt` package index.

    ```bash
    $ sudo apt-get update
    ```

2.  Install the latest version of Docker CE, or go to the next step to install a
    specific version. Any existing installation of Docker is replaced.

    ```bash
    $ sudo apt-get install docker-ce
    ```

3.  On production systems, you should install a specific version of Docker CE
    instead of always using the latest. This output is truncated. List the
    available versions.

    ```bash
    $ apt-cache madison docker-ce

    docker-ce | 17.06.0~ce-0~ubuntu | https://download.docker.com/linux/ubuntu xenial/stable armhf Packages
    ```

    The contents of the list depend upon which repositories are enabled. Choose
    a specific version to install. The second column is the version string. The
    third column is the repository name, which indicates which repository the
    package is from and by extension its stability level. To install a specific
    version, append the version string to the package name and separate them by
    an equals sign (`=`):

    ```bash
    $ sudo apt-get install docker-ce=<VERSION>
    ```

    The Docker daemon starts automatically.

4.  Verify that Docker CE is installed correctly by running the armhf Ubuntu 
    image.

    ```bash
    $ sudo docker run armv7/armhf-ubuntu echo 'hello-world'
    ```

    This command downloads a test image and runs it in a container. When the
    container runs, it prints an informational message and exits.

## Manage Docker as a non-root user

The `docker` daemon binds to a Unix socket instead of a TCP port. By default
that Unix socket is owned by the user `root` and other users can only access it
using `sudo`. The `docker` daemon always runs as the `root` user.

If you don't want to use `sudo` when you use the `docker` command, create a Unix
group called `docker` and add users to it. When the `docker` daemon starts, it
makes the ownership of the Unix socket read/writable by the `docker` group.

To create the `docker` group and add your user:

1.  Create the `docker` group.

    ```bash
    $ sudo groupadd docker
    ```

2.  Add your user to the `docker` group.

    ```bash
    $ sudo usermod -aG docker $USER
    ```

3.  Log out and log back in so that your group membership is re-evaluated.

    If testing on a virtual machine, it may be necessary to restart the virtual machine for changes to take affect.

    On a desktop Linux environment such as X Windows, log out of your session completely and then log back in.

4.  Verify that you can run `docker` commands without `sudo`.

    ```bash
    $ docker run armhf/hello-world
    ```

    This command downloads a test image and runs it in a container. When the
    container runs, it prints an informational message and exits.

## Configure Docker to start on boot

Most current Linux distributions (RHEL, CentOS, Fedora, Ubuntu 16.04 and higher)
use [`systemd`](#systemd) to manage which services start when the system boots.
Ubuntu 14.10 and below use [`upstart`](#upstart).

### systemd

```bash
$ sudo systemctl enable docker
```

To disable this behavior, use `disable` instead.

```bash
$ sudo systemctl disable docker
```

## Uninstall Docker CE

1.  Uninstall the Docker CE package:

    ```bash
    $ sudo apt-get purge docker-ce
    ```

2.  Images, containers, volumes, or customized configuration files on your host
    are not automatically removed. To delete all images, containers, and
    volumes:

    ```bash
    $ sudo rm -rf /var/lib/docker
    ```

You must delete any edited configuration files manually.
