use clap::Parser;
use std::{net::IpAddr, str::FromStr};
use iddns::{update_dynamic_record, DynamicDNSCredentials};

#[derive(Parser, Debug)]
#[command(author, version, about, long_about = None)]
struct Args {
    fqdn: String,

    #[arg(short, long)]
    username: String,

    #[arg(short, long)]
    password: String,

    #[arg(short, long)]
    ip: String,
}

#[tokio::main]
async fn main() -> Result<(), anyhow::Error> {

    let args = Args::parse();

    let fqdn = args.fqdn;
    let ip = IpAddr::from_str(&args.ip)?;
    let credentials = DynamicDNSCredentials {
        username: args.username,
        password: args.password,
    };

    update_dynamic_record(&fqdn, &ip, &credentials).await?;

    Ok(())
}
