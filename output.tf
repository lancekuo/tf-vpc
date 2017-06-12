output "availability_zones" {
    value = "${join(",", data.aws_availability_zones.azs.names)}"
}

output "vpc_default_id" {
    value = "${aws_vpc.default.id}" 
}

output "subnet_public" {
    value = "${join(",", aws_subnet.public.*.id)}"
}
output "subnet_public_app" {
    value = "${join(",", aws_subnet.public-app.*.id)}"
}
output "subnet_private" {
    value = "${join(",", aws_subnet.private.*.id)}"
}
output "subnet_on_public" {
    value = "${var.subnet-on-public}"
}
output "subnet_per_zone" {
    value = "${var.subnet-per-zone}"
}
output "instance_per_subnet" {
    value = "${var.instance-per-subnet}"
}
output "swarm_manager_count" {
    value = "${var.swarm-manager-count}"
}
output "swarm_node_count" {
    value = "${var.swarm-node-count}"
}
