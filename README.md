# Infomaniak Dynamic DNS Client

## Install

Make sure `curl` is available and installed on your system.

Either clone or download this repository.

```shell script
$ git clone https://github.com/nhedger/iddns
cd iddns && chmod +x iddns.sh
```

## Usage
```shell script
iddns -u <username> -p <password> [-i <ip>] [-g <grabber>] HOSTNAME
iddns -c <config> [-u <username>] [-p <password>] [-i <ip>] [-g <grabber>] HOSTNAME
```

| Option | Short| Description|
|---|---|---|
|n/a|`-c`|Path to your configuration file|
|`IDDNS_USERNAME`|`-u`|The Dynamic DNS username, as configured in your Infomaniak Manager.|
|`IDDNS_PASSWORD`|`-p`|The Dynamic DNS password, as configured in your Infomaniak Manager. |
|`IDDNS_IP`|`-i`|The IP address to update the Dynamic DNS record with. This may be either an IPv4 or an IPv6. **Leave empty if you want this IP address to be grabbed automatically.** |
|`IDDNS_GRABBER`|`-g`|The URL of a custom API endpoint that returns you public IP address. This endpoint must return a text-only response containing only your IP address. **Leave empty to use the default endpoint :** `https://api.ipify.org/`|
|`HOSTNAME`| n/a |The hostname for which the record must be updated. **This must be a valid FQDN**|


### Using a configuration file

Sometimes, using a configuration file instead of exposing all your options on the command line is preferable. 
On such occasions you may pass the `-c` parameter followed by the path to your configuration file.

```shell script
$ iddns -c /path/to/config/file example.tld
```

All the options above except the `HOSTNAME` can be set from the configuration file.

**WARNING** : These options will be overridden by their equivalents if they are provided as arguments to the script.

You'll find a [example configuration file](config.example) in this repository.

## Credits

* [Nicolas Hedger](https://github.com/nhedger)

## License
The MIT License (MIT). Please see [License File](LICENSE.md) for more information