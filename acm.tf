#Creates ACM certificate and requests validation via DNS(Route53)
resource "aws_acm_certificate" "jenkins-lb-https" {
  provider          = aws.region-master
  domain_name       = join(".", ["jenkins", data.aws_route53_zone.dns.name])
  validation_method = "DNS"

  tags = {
    Environment = "Jenkins-ACM"
  }
}

resource "aws_acm_certificate_validation" "example" {
  provider        = aws.region-master
  certificate_arn = aws_acm_certificate.jenkins-lb-https.arn
  for_each        = aws_route53_record.cert_validation
  #validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
  validation_record_fqdns = [aws_route53_record.cert_validation[each.key].fqdn]
}