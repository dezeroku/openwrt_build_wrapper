output "instance_public_dns" {
  value = aws_spot_instance_request.openwrt_builder.public_dns
}
