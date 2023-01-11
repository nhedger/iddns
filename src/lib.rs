use std::{net::IpAddr};
use anyhow::Ok;
use thiserror::Error;

#[derive(Error, Debug)]
pub enum IddnsError {
    #[error("The domain name `{0}` cannot be found. Did you enable dynamic DNS ?")]
    FQDNNotFound(String),

    #[error("The domain name `{0}` is not a valid FQDN.")]
    InvalidFQDN(String),

    #[error("The provided credentials (username: `{0}`) are invalid.")]
    InvalidCredentials(String),

    #[error("Cannot update the A record because a conflicting AAAA record already exists for `{0}`.")]
    ConflictingIPv6Record(String),

    #[error("Cannot update the AAAA record because a conflicting A record already exists for `{0}`.")]
    ConflictingIPv4Record(String),

    #[error("The provided IP address `{0}` is invalid.")]
    InvalidIPAddress(String),

    #[error("An unknown error occured when trying to update `{0}` with IP address `{1}`.")]
    Unknown(String, String),
}

#[derive(Debug)]
pub struct DynamicDNSCredentials {
    pub username: String,
    pub password: String,
}

pub async fn update_dynamic_record<'ip>(fqdn: &str, ip: &'ip IpAddr, credentials: &DynamicDNSCredentials)->Result<&'ip IpAddr, anyhow::Error> {

    // Create an HTTP client
    let client = reqwest::Client::new();

    // Build the Dynamic DNS record update request
    let response = client.post("https://infomaniak.com/nic/update")
        .basic_auth(&credentials.username, Some(&credentials.password))
        .query(&[("hostname", fqdn), ("myip", ip.to_string().as_str())])
        .send()
        .await?
        .text()
        .await?;

    // If the IP was updated or if it already has the IP, we consider the
    // operation to be successful.
    if response.starts_with("good") || response.starts_with("nochg") {
        return Ok(ip)
    }

    // Handle errors
    return match response.as_str() {
        "nohost" => Err(IddnsError::FQDNNotFound(String::from(fqdn)).into()),
        "notfqdn" => Err(IddnsError::InvalidFQDN(String::from(fqdn)).into()),
        "badauth" => Err(IddnsError::InvalidCredentials(String::from(&credentials.username)).into()),
        "conflict A" => Err(IddnsError::ConflictingIPv6Record(ip.to_string()).into()),
        "conflict AAAA" => Err(IddnsError::ConflictingIPv4Record(ip.to_string()).into()),
        "The Target field's structure for a A-type entry is incorrect." => Err(IddnsError::InvalidIPAddress(ip.to_string()).into()),
        _ => Err(IddnsError::Unknown(String::from(fqdn), ip.to_string()).into()),
    }
}
