# Installing Koha on Rocky Linux 8.5

## Introduction

Koha only provides packages for Ubuntu and Debian. Out of curiosity, I 
set out to install it on another distribution, Rocky Linux 8.5. There 
are some guides available on the [Koha Wiki](https://wiki.koha-community.org/wiki/Category:Installation)
but most of them are outdated. More importantly, none of them cover 
how to do a site-based installation, like in Debian. As of writing this 
the latest Koha version is 21.11.01. This guide can also be helpful for
installing Koha on other distros.

### Ansible
I have created an [Ansible playbook](koha-install.yaml) that installs Koha, all its dependencies and
makes all the necessary changes so Koha can work on Rocky. It essentially automates
the whole [Installing Koha](#installing-koha) section.

## WARNING
I absolutely recommend installing Koha using the official packages on Debian 
or Ubuntu. Koha updates may break the configuration and you will have to 
spend time figuring out why things don't work.

## Preparation

### Disabling SELinux

I do not use SELinux. If you are using this in production, I assume you know 
how to properly configure it. To disalbe SELinux set ```SELINUX=disbled```
in ```/etc/selinux/config```.

## Installing Koha
Koha requires a lot of Perl dependencies. Some of them are available in the official 
repostiories, some in EPEL, while others have to be installed from CPAN.

### Download and extract the tarball
```
cd /tmp/
wget http://download.koha-community.org/koha-latest.tar.gz
tar -C ~ -xzf koha-latest.tar.gz
```

### Enable the EPEL and PowerTools repositories

```
sudo dnf config-manager --set-enabled powertools
sudo dnf install epel-release
```

### Add the Indexdata repository
The idzebra and yaz packages are provided by Indexdata. To add the indexdata repository,
download the GPG key. (Instructions from [here](https://ftp.indexdata.com/pub/idzebra/redhat/centos/8/README)

```
sudo rpm --import http://ftp.indexdata.com/pub/yum/centos/8/RPM-GPG-KEY-indexdata
```

Create a repository file ```sudo nano /etc/yum.repos.d/indexdata.repo``` and place the 
following:

```
[indexdata-main]
name=Index Data Main Repository
baseurl=https://ftp.indexdata.com/pub/yum/centos/8/main/$basearch
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-indexdata
enabled=1
priority=1
```

### Install mpm-itk
Mpm-itk is required by Koha, but it is not available in the official repos or EPEL. It is 
avaiable on the unofficial Lux repository. Add it and install mpm-itk. If you don't want 
to add the repository, you can download just the rpm and install it.

```
sudo rpm -Uvh http://repo.iotti.biz/CentOS/5/noarch/lux-release-0-1.noarch.rpm
sudo rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-LUX
sudo dnf install httpd-itk
```

### Install RabbitMQ

```
sudo dnf install centos-release-rabbitmq-38
sudo dnf install rabbitmq-server
```

Enable the stomp plugin

```
echo "[rabbitmq_stomp]." | sudo tee -a /etc/rabbitmq/enabled_plugins
```

### Install packages from the repositories

Koha provides the ```koha_perl_deps.pl``` script that detects missing Perl dependencies.
In order to find which packages are available in the repositories I created the 
```find-deps.sh``` script, which is available in this repository. 

Install non-perl dependencies.

```
sudo dnf install idzebra-2.0 \
           libidzebra-2.0 \
           libidzebra-2.0-devel \
           libidzebra-2.0-modules \
           memcached \
           gcc \
           make \
           yaz \
           libyaz5 \
           libyaz5-devel \
           libuuid-devel \
           fribidi \
           fribidi-devel \
           pwgen \
           xmlstarlet \
           redhat-lsb-core
```

Install Perl and cpanm.

```
sudo dnf install perl perl-App-cpanminus
```

Install Perl packages from the repositories:

```
sudo dnf install GraphicsMagick-perl \
           perl-AnyEvent-HTTP \
           perl-Archive-Extract \
           perl-Array-Utils \
           perl-Business-ISBN \
           perl-Bytes-Random-Secure \
           perl-Cache-Memcached \
           perl-CGI \
           perl-CGI-Compile \
           perl-CGI-Emulate-PSGI \
           perl-Class-Accessor \
           perl-Class-Inspector \
           perl-Crypt-Eksblowfish \
           perl-Date-Calc \
           perl-Date-Manip \
           perl-DateTime-Event-ICal \
           perl-DateTime-Format-ICal \
           perl-DateTime-Format-MySQL \
           perl-DateTimeX-Easy \
           perl-DBD-Mock \
           perl-DBD-MySQL \
           perl-DBI \
           perl-DBIx-RunSQL \
           perl-Devel-Cover \
           perl-Email-Address \
           perl-Email-MessageID \
           perl-Email-Sender \
           perl-ExtUtils-PkgConfig \
           perl-File-Slurp \
           perl-Font-TTF \
           perl-GD \
           perl-GD-Barcode \
           perl-HTML-Formatter \
           perl-HTML-Parser \
           perl-HTML-Scrubber \
           perl-HTTP-Cookies \
           perl-HTTP-Daemon \
           perl-HTTP-Message \
           perl-JSON \
           perl-LDAP \
           perl-libintl-perl \
           perl-libwww-perl \
           perl-Log-Log4perl \
           perl-LWP-Protocol-https \
           perl-MIME-Lite \
           perl-Module-Pluggable \
           perl-Mojolicious \
           perl-Moo \
           perl-Net-CIDR \
           perl-Net-Netmask \
           perl-Net-Server \
           perl-Net-SFTP-Foreign \
           perl-Number-Format \
           perl-Parallel-ForkManager \
           perl-Plack-Test \
           perl-Plack-Middleware-ReverseProxy \
           perl-Readonly \
           perl-Sereal-Decoder \
           perl-Sereal-Encoder \
           perl-String-Random \
           perl-Sys-CPU \
           perl-Template-Toolkit \
           perl-Test-Deep \
           perl-Test-Exception \
           perl-Test-MockModule \
           perl-Test-MockObject \
           perl-Test-MockTime \
           perl-Test-Mojo \
           perl-Test-Warn \
           perl-Test-WWW-Mechanize \
           perl-Text-CSV \
           perl-Text-CSV_XS \
           perl-Text-Iconv \
           perl-Text-Unidecode \
           perl-Time-Fake \
           perl-Try-Tiny \
           perl-UNIVERSAL-require \
           perl-UNIVERSAL-can \
           perl-XML-Dumper \
           perl-XML-LibXML \
           perl-XML-LibXSLT \
           perl-XML-RSS \
           perl-XML-SAX \
           perl-XML-SAX-Writer \
           perl-XML-Simple \
           perl-XML-Writer
```

### Install packages from CPAN

Install packages from CPAN: (Note: some packages might fail to install, usually because 
a dependency is missing. It will usually be in the install logs.)

```
cpanm --sudo Algorithm::CheckDigits \
         Alien::Tidyp \
         AnyEvent \
         Authen::CAS::Client \
         Biblio::EndnoteStyle \
         Business::ISSN \
         Cache::Memcached::Fast::Safe \
         CGI::Session \
         CGI::Session::Driver::memcached \
         Class::Factory::Util \
         Clone \
         Data::ICal \
         DateTime \
         DateTime::TimeZone \
         DBD::SQLite2 \
         DBIx::Class::Schema::Loader \
         Email::Date \
         Email::Stuffer \
         Exception::Class \
         Gravatar::URL \
         HTTPD::Bench::ApacheBench \
         HTTP::OAI \
         JSON::Validator \
         JSON::Validator::Ref \
         JSON::Validator::OpenAPI::Mojolicious \
         Library::CallNumber::LC \
         Lingua::Ispell \
         Lingua::Stem \
         Lingua::Stem::Snowball \
         List::MoreUtils \
         Locale::Currency::Format \
         Locale::PO \
         Locale::XGettext::TT2 \
         MARC::Charset \
         MARC::File::XML \
         MARC::Record \
         MARC::Record::MiJ \
         Module::Bundled::Files \
         Mojolicious::Plugin::OpenAPI \
         Net::OAuth2::AuthorizationServer \
         Net::Stomp \
         Net::Z3950::SimpleServer \
         Net::Z3950::ZOOM \
         OpenOffice::OODoc \
         PDF::API2 \
         PDF::FromHTML \
         PDF::Reuse \
         PDF::Reuse::Barcode \
         PDF::Table \
         Plack::Middleware::LogWarn \
         Schedule::At \
         Search::Elasticsearch \
         Selenium::Remote::Driver \
         SMS::Send \
         Starman \
         Template::Plugin::HtmlToText \
         Template::Plugin::JSON::Escape \
         Template::Plugin::Stash \
         Test::DBIx::Class \
         Test::Strict \
         Test::YAML::Valid \
         Text::Bidi \
         Text::CSV::Encoded \
         Text::CSV::Unicode \
         Text::PDF \
         UUID \
         WebService::ILS \
         WWW::CSRF \
         YAML::XS
```

Note: ```JSON::Validator::OpenAPI::Mojolicious``` might throw some errors, but they can be ignored. To force intall it run:

```
cpanm --sudo --force JSON::Validator::OpenAPI::Mojolicious
```

### Link Zebra files

Koha expects some executables and modules to be in a different location. Create some symlinks so it can find them:

```
sudo ln -s /usr/bin/zebraidx-2.0 /usr/bin/zebraidx
sudo ln -s /usr/bin/zebrasrv-2.0 /usr/bin/zebrasrv
sudo ln -s /usr/lib64/idzebra-2.0 /usr/lib/
```


### Create Koha user

This is done before installing the main Koha files, because make install sets permissions on Koha directories.

```
sudo groupadd -r koha
sudo useradd -r -s /usr/bin/nologin -g koha -G apache koha
```

### Install Koha

```
PERL_MM_USE_DEFAULT=1 perl Makefile.PL; make; sudo make install
```

### Copy additional Koha scripts and files

The Debian Koha package contains some additional template files and scripts. These scripts are made for Debian and 

```
sudo cp debian/templates/* /etc/koha/
sudo cp debian/scripts/* /usr/share/koha/bin/
```

Additionally, create symlinks to /usr/sbin, so you can use the scripts directly from the command line:

```
sudo ln -s /usr/share/koha/bin/koha-* /usr/sbin/
sudo rm /usr/sbin/{koha-functions.sh,koha-zebra-ctl.sh,koha-index-daemon-ctl.sh}
```

### Enable MPM-ITK

Edit ```/etc/httpd/conf.modules.d/00-mpm.conf```. Comment out ```mpm_event``` and enable 
```mpm_prefork```.

```
LoadModule mpm_prefork_module modules/mod_mpm_prefork.so
[...]
#LoadModule mpm_event_module modules/mod_mpm_event.so
```

Edit ```/etc/httpd/conf.modules.d/00-mpm-itk.conf``` and enable the module.

```
LoadModule mpm_itk_module modules/mod_mpm_itk.so
```

### Patch the included Koha scripts

The scripts included with Koha are made with Debian with mind. I have created some patches, that allows them to 
function in Rocky. The necessary patches are in the ```patches``` directory in this repository. For example to 
patch ```koha-create``` run:

```
sudo patch /usr/share/koha/bin/koha-create < koha-create.patch
```

For a list of scripts that have been confirmed to work check out the [Script Status section](#script-status)

### Configure Apache

By default Apache on Rocky does not allow access to ```/usr/share/koha```. Add the following to 
```/etc/httpd/conf/httpd.conf```.

```
<Directory /usr/share/koha>
    Require all granted
</Directory>
```

### Install systemd services.

Koha normally starts its services using shell scripts. However, these scripts use the 
daemon command that is only available for Debian. Instead of scripts, I have created some systemd 
service files that start Koha services. Copy the .service files from this repository into 
```/etc/systemd/system```.

### Enable services

Enable memcached and RabbitMQ.

```
sudo systemctl enable --now memcached rabbitmq-server
```

## Configure library

After you have created the database, using koha-create as described in the original guide, continue from here.

### Enable library services

Enable the Koha services, replacing ```library``` with the library name you used in ```koha-create```

```
sudo systemctl enable --now koha-create-dirs@library  koha-plack@library koha-indexer@library koha-worker@library koha-zebra@library
```

### Enable Plack

To enable Plack edit ```/etc/httpd/conf.d/library.conf``` uncomment

```
  Include /etc/koha/apache-shared-opac-plack.conf
  [...]
  Include /etc/koha/apache-shared-intranet-plack.conf
```

You will get some permission errors. To fix them run:

```
sudo chown -R library-koha:library-koha /var/log/koha/library/
```

## Script status


### Working scripts

koha-create-dirs

koha-email-enable

koha-foreach

koha-mysql

koha-mysqlcheck

koha-passwd

koha-rebuild-zebra

koha-sitemap

koha-shell

koha-translate

koha-upgrade-schema (probably?)

### Working with patch

koha-create

koha-disable

koha-dump

koha-enable

koha-list

koha-run-backups

### Not working scripts

Replaced by systemd services:

* koha-indexer

* koha-plack

* koha-worker

* koha-z3950-responder

* koha-zebra

## Next steps

The installation is complete. You should be able to access the web interface and configure your instance. You can continue with the rest of the guide.
