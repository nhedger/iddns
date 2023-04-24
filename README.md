# Infomaniak Dynamic DNS Client

`iddns` is an easy-to-use dynamic DNS updater for the *Infomaniak Dynamic DNS* service written in bash.

## Install

Make sure `curl` is available and installed on your system. `make` is also required if you want to use the Makefile for installing
the script automatically.

Either clone or [download](https://github.com/nhedger/iddns/archive/legacy.zip) this repository.

```shell script
$ git clone -b legacy https://github.com/nhedger/iddns
cd iddns
make install
```

Run `make uninstall` from the same directory if you want to completely remove `iddns` from your system.

## Usage
```shell script
iddns [options] HOSTNAME
```

| Option| Expected value |Description|
|---|---|---|
|`-s`|None, it's a flag|Silences all output|
|`-t`|None, it's a flag|Prefixes all output with a timestamp. Useful when logging|
|`-c`|Path to configuration file|Custom configuration file. See below for more information
|`-u`|Username|Dynamic DNS username, as configured in your [Infomaniak Manager](https://manager.infomaniak.com)|
|`-p`|Password|Dynamic DNS password, as configured in your [Infomaniak Manager](https://manager.infomaniak.com)|
|`-i`|IPv4 or IPv6|The IP address to update the Dynamic DNS record with|
|`-g`|URL|Custom API endpoint that returns only your public IP address as text-only|
|`-v`|None, it's a flag|Displays the version|
|`HOSTNAME`|Valid FQDN|The hostname for which the record must be updated|

### Using a configuration file

Sometimes, using a configuration file instead of exposing all your options on the command line is preferable.
On such occasions you may pass the `-c` parameter followed by the path to your configuration file.

```shell script
$ iddns -c /path/to/config/file example.tld
```

`iddns` will also try to load automatically a default configuration file named `$HOME/.iddns` if it exists and no alternative configuration file was passed on the command line.

#### Valid configuration options
| Option | Expected value | Description |
|---|---|---|
|`IDDNS_SILENT`|`true`/`false`|Silences all output|
|`IDDNS_TIMESTAMPS`|`true`/`false`|Prefixes all output with a timestamp. Useful when logging|
|`IDDNS_USERNAME`|Username|Dynamic DNS username, as configured in your [Infomaniak Manager](https://manager.infomaniak.com)|
|`IDDNS_PASSWORD`|Password|Dynamic DNS password, as configured in your [Infomaniak Manager](https://manager.infomaniak.com)|
|`IDDNS_IP`|IPv4 or IPv6|The IP address to update the Dynamic DNS record with|
|`IDDNS_GRABBER`|URL|Custom API endpoint that returns only your public IP address as text-only|

**WARNING** : Options declared on the command line have a higher priority so they will override any of these values when set.

You'll find a [example configuration file](config.example) in this repository.

## Scheduling updates

You may automate your updates by setting up a cron job for `iddns`.

Create a configuration file that holds your credentials:

```shell script
IDDNS_USERNAME="example"
IDDNS_PASSWORD="password"
```

Create a `/etc/cron.d/iddns` file with the following contents (replace with the path to your config file and hostname) :

```shell script
0 * * * * root /usr/local/bin/iddns -t -c /path/to/config example.tld >> /var/log/iddns.log 2>&1
```

This will run `iddns` every hour and log its output to `/var/log/iddns.log`.


## Credits

* [Nicolas Hedger](https://github.com/nhedger)

## License
The MIT License (MIT). Please see [License File](LICENSE.md) for more information
