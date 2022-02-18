variable "region" {
  type        = string
  description = "The region to deploy resources in. Currently, this all needs to be deployed in us-east-1 to work properly, but this may change in the future."
  default     = "us-east-1"
}

variable "acm_certificate_arn" {
  type        = string
  description = "The ACM certificate to use for the CloudFront distribution. If this is left blank, one will be created."
  default     = ""
}

// root domain
variable "domain_name" {
  type        = string
  description = "The root domain."
}

variable "use_root_domain" {
  type        = bool
  description = "Should the root domain, passed in via the domain_name variable, be used as an alias for the CloudFront distribution?"
  default     = true
}

variable "target_origin" {
  type        = string
  description = "The URL to be cached behind CloudFront. this-is-a-very-lengthy-url-that-is-NOT-VALID-AT-ALL.s3-website-us-northbynorthwest-1.amazonaws.com"
}

variable "origin_root_object" {
  type        = string
  description = "index.html or another default page/object to be delivered when a client requests the bare domain"
  default     = "/"
}

variable "use_wafv2" {
  type        = string
  description = "Determines whether or not to use WAFv2 for the web ACL. If true, a WAFv2 ACL will be created. If false, WAFv1 will be used."
  default     = true
}

variable "rate_limit" {
  type        = number
  description = "The maximum number of requests in a 5 minute span allowed from a single IP address. Used with WAFv2, default is the same as the WAFv1 default."
  default     = 2000
}

variable "http_port" {
  type        = number
  description = "The port to use for HTTP requests. Defaults to 80."
  default     = 80
}

variable "https_port" {
  type        = number
  description = "The port to use for HTTPS requests. Defaults to 443."
  default     = 443
}

variable "origin_protocol_policy" {
  type        = string
  description = "The origin protocol policy to apply to your origin. If using an S3 origin, HTTP only; HTTPS is handled by the CloudFront distribution. Valid values are http-only, https-only, or match-viewer."
  default     = "http-only"
}

variable "origin_ssl_protocols" {
  type        = list(string)
  description = "The list of SSL/TLS protocols that you want CloudFront to use when communicating with the origin over HTTPS."
  default     = ["TLSv1.2"]
}

variable "allowed_http_methods" {
  type        = list(string)
  description = "Controls which HTTP methods CloudFront processes and forwards to the origin."
  default     = ["GET", "HEAD"]
}

variable "cached_http_methods" {
  type        = list(string)
  description = "Controls which HTTP methods CloudFront caches the response to requests for."
  default     = ["GET", "HEAD"]
}

variable "compress_content" {
  type        = bool
  description = "Whether you want CloudFront to automatically compress content for web requests that include 'Accept-Encoding: gzip' in the header."
  default     = true
}

variable "min_ttl" {
  type        = number
  description = "Minimum length of time (in seconds) objects should stay in cache before CloudFront queries the origin for updates."
  default     = 0
}

variable "max_ttl" {
  type        = number
  description = "Maximum length of time (in seconds) objects should stay in cache before CloudFront queries the origin for updates."
  default     = 7200
}

variable "default_ttl" {
  type        = number
  description = "Default length of time (in seconds) objects should stay in cache before CloudFront queries the origin for updates."
  default     = 3600
}

variable "alternate_domains" {
  type        = list(string)
  description = "A list of all domain names, CNAMEs, and other records that should point to the origin."
  default     = []
}

variable "georestriction_type" {
  type        = string
  description = "Method used to restrict distribution of the content by country. Can be whitelist, blacklist, or none."
  default     = "none"
}

variable "georestriction_countries" {
  type        = list(string)
  description = "List of ISO 3166-1-alpha-2 codes for countries to either allow or disallow distribution to."
  default     = []
}
