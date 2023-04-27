use clap::Parser;
use iddns::{DynamicDNSRecord, DynamicDNSUpdateConfig};
use std::net::IpAddr;

/// Infomaniak Dynamic DNS update client
#[derive(Parser, Debug)]
#[command(author, version, about, long_about)]
struct Args {
    #[arg(help = "Fully qualified domain name of the record")]
    fqdn: String,

    #[arg(long, short, help = "Infomaniak Dynamic DNS username")]
    username: String,

    #[arg(long, short, help = "Infomaniak Dynamic DNS password")]
    password: String,

    #[arg(
        long,
        short,
        help = "Manually specified IP address to use for the update"
    )]
    ip: Option<IpAddr>,

    #[arg(
        long,
        short = 'U',
        help = "URL of the service to use for IP address discovery"
    )]
    url: Option<String>,
}

fn main() {
    let args = Args::parse();

    let config = DynamicDNSUpdateConfig {
        username: args.username,
        password: args.password,
        ip: args.ip,
        url: args.url,
    };

    let record = DynamicDNSRecord {
        fqdn: args.fqdn,
        config,
    };

    match record.update() {
        Ok(ip) => println!("{}", ip),
        Err(e) => eprintln!("{}", e),
    }
}
