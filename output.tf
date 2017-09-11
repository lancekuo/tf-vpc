output "availability_zones" {
    value = ["${data.aws_availability_zones.azs.names}"]
}

output "vpc_default_id" {
    value = "${aws_vpc.default.id}" 
}

output "subnet_public_bastion_ids" {
    value = ["${aws_subnet.public-bastion.*.id}"]
}
output "subnet_public_app_ids" {
    value = ["$aws_subnet.public-app.*.id}"]
}
output "subnet_private_ids" {
    value = ["$aws_subnet.private.*.id}"]
}
output "route53_internal_zone_id" {
    value = "${aws_route53_zone.internal.zone_id}"
}
