use anyhow::Result;
use std::net::IpAddr;
use std::str::FromStr;
use thiserror::Error;

#[derive(Error, Debug)]
pub enum DynamicDNSUpdateError {
    #[error("The domain name `{0}` cannot be found. Did you enable dynamic DNS ?")]
    FQDNNotFound(String),

    #[error("The domain name `{0}` is not a valid FQDN.")]
    InvalidFQDN(String),

    #[error("The provided credentials (username: `{0}`) are invalid.")]
    InvalidCredentials(String),

    #[error(
        "Cannot update the A record because a conflicting AAAA record already exists for `{0}`."
    )]
    ConflictingIPv6Record(String),

    #[error(
        "Cannot update the AAAA record because a conflicting A record already exists for `{0}`."
    )]
    ConflictingIPv4Record(String),

    #[error("The provided IP address `{0}` is invalid.")]
    InvalidIPAddress(String),

    #[error("Unable to parse the string into a valid IP address: `{0}`.")]
    UnableToParseIPAddress(String),

    #[error("An unknown error occurred when trying to update `{0}` with IP address `{1}`.")]
    Unknown(String, String),
}

pub struct DynamicDNSUpdateConfig {
    /// Infomaniak Dynamic DNS username
    pub username: String,

    /// Infomaniak Dynamic DNS password
    pub password: String,

    /// Manually specified IP address to use for the update
    pub ip: Option<IpAddr>,

    /// URL of the service to use for IP address discovery
    pub url: Option<String>,
}

pub struct DynamicDNSRecord {
    /// Fully qualified domain name of the record
    pub fqdn: String,

    /// Update configuration for the record
    pub config: DynamicDNSUpdateConfig,
}

impl DynamicDNSRecord {
    /// Update the record
    ///
    /// This method updates the dynamic DNS record and returns the new IP address.
    pub fn update(&self) -> Result<IpAddr> {
        // Get the IP address to use for the update
        let new_ip = match self.config.ip {
            Some(ip) => ip,
            None => self.discover_ip()?,
        };

        // Create an HTTP client
        let client = reqwest::blocking::Client::new();

        // Attempt to update the dynamic DNS record
        let response = client
            .post("https://infomaniak.com/nic/update")
            .basic_auth(&self.config.username, Some(&self.config.password))
            .query(&[("hostname", &self.fqdn), ("myip", &new_ip.to_string())])
            .send()?
            .text()?;

        // If the update was successful, or if the IP address is already up to date, return the new IP address.
        if response.starts_with("good") || response.starts_with("nochg") {
            let ip = response.split_whitespace().nth(1).unwrap();
            return Ok(IpAddr::from_str(ip)?);
        }

        // Handle errors
        return match response.as_str() {
            "nohost" => Err(DynamicDNSUpdateError::FQDNNotFound(self.fqdn.clone()).into()),
            "notfqdn" => Err(DynamicDNSUpdateError::InvalidFQDN(self.fqdn.clone()).into()),
            "badauth" => Err(DynamicDNSUpdateError::InvalidCredentials(String::from(
                self.config.username.clone(),
            ))
            .into()),
            "conflict A" => {
                Err(DynamicDNSUpdateError::ConflictingIPv6Record(new_ip.to_string()).into())
            }
            "conflict AAAA" => {
                Err(DynamicDNSUpdateError::ConflictingIPv4Record(new_ip.to_string()).into())
            }
            "The Target field's structure for a A-type entry is incorrect." => {
                Err(DynamicDNSUpdateError::InvalidIPAddress(new_ip.to_string()).into())
            }
            _ => Err(DynamicDNSUpdateError::Unknown(self.fqdn.clone(), new_ip.to_string()).into()),
        };
    }

    fn discover_ip(&self) -> Result<IpAddr> {
        // If a URL was not specified, use the fallback URL on APIFY
        let url = match &self.config.url {
            Some(url) => url.clone(),
            None => String::from("https://api.ipify.org/?format=text"),
        };

        // Create an HTTP client
        let client = reqwest::blocking::Client::new();

        // Attempt to discover the IP address
        let response = client.get(url).send()?.text()?;

        let discovered_ip = IpAddr::from_str(&response.trim());

        return match discovered_ip {
            Ok(ip) => Ok(ip),
            Err(_) => Err(DynamicDNSUpdateError::UnableToParseIPAddress(
                response.trim().to_string(),
            )
            .into()),
        };
    }
}
