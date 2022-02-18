module "cf_waf_acm" {
  source = "./cf_waf_acm"

  domain_name   = var.root_domain_name
  target_origin = aws_alb.quest_alb.dns_name
}
