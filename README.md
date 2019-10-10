# Infomaniak Dynamic DNS Client

`iddns` is an easy-to-use dynamic DNS updater for the *Infomaniak Dynamic DNS* service written in bash.

## Install

Make sure `curl` is available and installed on your system. `make` is also required if you want to use the Makefile for installing
the script automatically.

Either clone or [download](https://github.com/nhedger/iddns/archive/master.zip) this repository.

```shell script
$ git clone https://github.com/nhedger/iddns
cd iddns
make install
```

Run `make uninstall` from the same directory if you want to completely remove `iddns` from your system.

## Usage
```shell script
iddns -u <username> -p <password> [-i <ip>] [-g <grabber>] [-t] [-s] HOSTNAME
iddns -c <config> [-u <username>] [-p <password>] [-i <ip>] [-g <grabber>] [-t] [-s] HOSTNAME
```

| Option | Short| Description|
|---|---|---|
|n/a|`-c`|Path to your configuration file|
|`IDDNS_USERNAME`|`-u`|The Dynamic DNS username, as configured in your Infomaniak Manager.|
|`IDDNS_PASSWORD`|`-p`|The Dynamic DNS password, as configured in your Infomaniak Manager. |
|`IDDNS_IP`|`-i`|The IP address to update the Dynamic DNS record with. This may be either an IPv4 or an IPv6. **Leave empty if you want this IP address to be grabbed automatically.** |
|`IDDNS_GRABBER`|`-g`|The URL of a custom API endpoint that returns you public IP address. This endpoint must return a text-only response containing only your IP address. **Leave empty to use the default endpoint :** `https://api.ipify.org/`|
|`IDDNS_TIMESTAMPS`|`-t`|All output is prefixed with the current timestamp. This is particularly useful when outputting to a log file.
|`IDDNS_SILENT`|`-s`|No output will be generated if this flag is active.|
|`HOSTNAME`| n/a |The hostname for which the record must be updated. **This must be a valid FQDN and the dynamic record must already exist in your Infomaniak Manager.**|

### Using a configuration file

Sometimes, using a configuration file instead of exposing all your options on the command line is preferable. 
On such occasions you may pass the `-c` parameter followed by the path to your configuration file.

```shell script
$ iddns -c /path/to/config/file example.tld
```

`iddns` will also try to load automatically a default configuration file named `$HOME/.iddns` if it exists and no alternative configuration file was passed on the command line.

All the options above except the `HOSTNAME` can be set from the configuration file.

**WARNING** : These options will be overridden by their equivalents if they are provided as arguments on the command line.

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
