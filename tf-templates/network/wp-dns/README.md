# template: network/wp-dns

Provisions the complete DNS, SSL, and routing configuration for a single WordPress hosted site: Route53 hosted zone, ALB alias records (apex and www), MX records, and an ACM certificate.

## Resources Provisioned

- **Route53 public zone** — Hosted zone for the domain, created with the account-level delegation set for consistent name servers
- **ALB alias records** — Apex domain (`example.co.uk`) and `www` subdomain both alias to the Application Load Balancer DNS name
- **MX records** — Mail exchange records for the domain
- **ACM certificate** — SSL certificate covering the apex domain and `www` SAN, with DNS validation records created in the Route53 zone

## Notes

- This template is applied once per hosted domain. All eight WordPress domains in the platform each have their own params directory under `hosted-sites/`.
- The delegation set used must already exist (created by the `account` template). The name servers in the delegation set must be registered with the domain registrar before DNS will resolve.
- The ACM certificate waits for DNS validation to complete before marking the resource as created, so plan time is short but apply may take several minutes on first run.

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
