#########################
## AWS Route 53 Module ##
#########################

// Registered Domains: these are for importing the domains but will not build or destroy //
resource "aws_route53domains_registered_domain" "trace_auto_ninja" {
  domain_name = "trace-auto.ninja"
}

resource "aws_route53domains_registered_domain" "trace_cloud_site" {
  domain_name = "trace-cloud-site.com"
}

resource "aws_route53domains_registered_domain" "trace_cloud_resume" {
  domain_name = "trace-cloud-resume.com"
}

resource "aws_route53_zone" "root_domain" {
  name = aws_route53domains_registered_domain.trace_auto_ninja.domain_name
  tags = {
    "Name" = "website_hosted_zone"
  }
}

resource "aws_route53_record" "root_domain" {
  zone_id = aws_route53_zone.root_domain.zone_id
  name    = aws_route53domains_registered_domain.trace_auto_ninja.domain_name
  type    = "A"

  alias {
    evaluate_target_health = false
    name                   = data.terraform_remote_state.s3.outputs.hosting_bucket.website_domain
    zone_id                = data.terraform_remote_state.s3.outputs.hosting_bucket.hosted_zone_id
  }
}

resource "aws_route53_health_check" "root_domain" {
  fqdn              = aws_route53domains_registered_domain.trace_auto_ninja.domain_name
  port              = 80
  type              = "HTTP"
  resource_path     = "/"
  failure_threshold = "5"
  request_interval  = "30"

  tags = {
    Name = "root-website-dns-health-check"
  }
}

resource "aws_route53_health_check" "sub_domain" {
  fqdn              = "www.${aws_route53domains_registered_domain.trace_auto_ninja.domain_name}"
  port              = 80
  type              = "HTTP"
  resource_path     = "/"
  failure_threshold = "5"
  request_interval  = "30"

  tags = {
    Name = "sub-website-dns-health-check"
  }
}

resource "aws_route53_record" "sub_domain" {
  zone_id = aws_route53_zone.root_domain.id
  name    = "www.${aws_route53domains_registered_domain.trace_auto_ninja.domain_name}"
  type    = "A"

  alias {
    name                   = trimsuffix(data.terraform_remote_state.s3.outputs.redirect_bucket.website_domain, ".")
    zone_id                = data.terraform_remote_state.s3.outputs.redirect_bucket.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_acm_certificate" "website_validation" {
  domain_name       = aws_route53_zone.root_domain.name
  validation_method = "DNS"
  subject_alternative_names = [
    "*.${aws_route53_zone.root_domain.name}"
  ]
  tags = {
    Name = "${aws_route53_zone.root_domain.name}_cert"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "website_validation" {
  for_each = {
    for cert in aws_acm_certificate.website_validation.domain_validation_options : cert.domain_name => {
      name   = cert.resource_record_name
      record = cert.resource_record_value
      type   = cert.resource_record_type
    }
  }
  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.root_domain.id
}

output "acm_cert" {
  value = {
    validation_method         = aws_acm_certificate.website_validation.validation_method
    subject_alternative_names = aws_acm_certificate.website_validation.subject_alternative_names
    domain_name               = aws_acm_certificate.website_validation.domain_name
  }
}

output "acm_validation" {
  value = {
    for k in aws_acm_certificate.website_validation.domain_validation_options : k.domain_name => {
      name  = k.resource_record_name
      type  = k.resource_record_type
      value = k.resource_record_value
    }
  }
}

output "sub_domain_route53_record" {
  value = aws_route53_record.sub_domain
}


output "root_domain_route53_record" {
  value = aws_route53_record.root_domain
}

output "aws_route53_zone" {
  value = aws_route53_zone.root_domain
}
