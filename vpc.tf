resource "aws_vpc" "default" {
    cidr_block           = "${lookup(var.subnets_map, terraform.workspace)}"
    enable_dns_support   = true
    enable_dns_hostnames = true
    tags  {
        Name        = "${terraform.workspace}-${var.project}"
        Environment = "${terraform.workspace}"
    }
}

resource "aws_vpc_dhcp_options_association" "custom_domain" {
    vpc_id          = "${aws_vpc.default.id}"
    dhcp_options_id = "${aws_vpc_dhcp_options.custom_domain.id}"
}

resource "aws_vpc_dhcp_options" "custom_domain" {
  domain_name         = "${terraform.workspace}.${var.project}.internal"
  domain_name_servers = ["AmazonProvidedDNS"]
}
resource "aws_internet_gateway" "default" {
    vpc_id   = "${aws_vpc.default.id}"
    tags {
        Name        = "${terraform.workspace} internet gateway"
        Environment = "${terraform.workspace}"
    }
}

resource "aws_nat_gateway" "default" {
    count         = "${var.count_private_subnet_per_az > 0 ? 1 : 0}"
    allocation_id = "${aws_eip.nat.id}"
    subnet_id     = "${aws_subnet.public-app.0.id}"
    tags {
        Name        = "${terraform.workspace} NAT gateway"
        Environment = "${terraform.workspace}"
    }
    depends_on    = ["aws_internet_gateway.default"]
}

resource "aws_eip" "nat" {
    vpc      = true
    tags {
        Name        = "${terraform.workspace} NAT gateway"
        Environment = "${terraform.workspace}"
    }
}

resource "aws_default_route_table" "public" {
    default_route_table_id = "${aws_vpc.default.default_route_table_id}"
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.default.id}"
    }
    tags {
        Name        = "public-route"
        Environment = "${terraform.workspace}"
    }
}

resource "aws_route_table" "private" {
    count    = "${var.count_private_subnet_per_az > 0 ? 1 : 0}"
    vpc_id   = "${aws_vpc.default.id}"
    route {
        cidr_block     = "0.0.0.0/0"
        nat_gateway_id = "${aws_nat_gateway.default.id}"
    }
    tags {
        Name        = "private-route"
        Environment = "${terraform.workspace}"
    }
}

resource "aws_subnet" "public-bastion" {
    count                   = "${var.count_bastion_subnet_on_public}"
    vpc_id                  = "${aws_vpc.default.id}"
    cidr_block              = "${replace(lookup(var.subnets_map, "${terraform.workspace}_subnet_template"), "PLACEHOLDER", lookup(var.subnets_map, "bastion_def")+count.index)}"
    availability_zone       = "${element(data.aws_availability_zones.azs.names, count.index)}"
    map_public_ip_on_launch = true
    tags  {
        Name        = "public-bastion-${count.index}"
        Environment = "${terraform.workspace}"
    }
}
resource "aws_subnet" "public-app" {
    count                   = "${var.count_public_subnet_per_az*length(data.aws_availability_zones.azs.names)}"
    vpc_id                  = "${aws_vpc.default.id}"
    cidr_block              = "${replace(lookup(var.subnets_map, "${terraform.workspace}_subnet_template"), "PLACEHOLDER", lookup(var.subnets_map, "app_def")+count.index)}"
    availability_zone       = "${element(data.aws_availability_zones.azs.names, count.index)}"
    map_public_ip_on_launch = true
    tags {
        Name        = "public-app-${count.index}"
        Environment = "${terraform.workspace}"
    }
}

resource "aws_subnet" "private" {
    count                   = "${var.count_private_subnet_per_az*length(data.aws_availability_zones.azs.names)}"
    vpc_id                  = "${aws_vpc.default.id}"
    cidr_block              = "${replace(lookup(var.subnets_map, "${terraform.workspace}_subnet_template"), "PLACEHOLDER", lookup(var.subnets_map, "private_def")+count.index)}"
    availability_zone       = "${element(data.aws_availability_zones.azs.names, count.index)}"
    map_public_ip_on_launch = false
    tags {
        Name        = "private-${count.index}"
        Environment = "${terraform.workspace}"
    }
}

resource "aws_route_table_association" "public-route" {
    count          = "${var.count_bastion_subnet_on_public}"
    subnet_id      = "${element(aws_subnet.public-bastion.*.id, count.index)}"
    route_table_id = "${aws_default_route_table.public.id}"
}

resource "aws_route_table_association" "public-app-route" {
    count          = "${var.count_public_subnet_per_az*length(data.aws_availability_zones.azs.names)}"
    subnet_id      = "${element(aws_subnet.public-app.*.id, count.index)}"
    route_table_id = "${aws_default_route_table.public.id}"
}

resource "aws_route_table_association" "private-route" {
    count          = "${var.count_private_subnet_per_az*length(data.aws_availability_zones.azs.names)}"
    subnet_id      = "${element(aws_subnet.private.*.id, count.index)}"
    route_table_id = "${aws_route_table.private.id}"
}

resource "aws_network_acl" "private" {
    vpc_id     = "${aws_vpc.default.id}"
    subnet_ids = ["${aws_subnet.private.*.id}"]
    ingress {
        protocol   = "-1"
        rule_no    = 100
        action     = "allow"
        cidr_block = "0.0.0.0/0"
        from_port  = 0
        to_port    = 0
    }
    egress {
        protocol   = "-1"
        rule_no    = 100
        action     = "allow"
        cidr_block = "0.0.0.0/0"
        from_port  = 0
        to_port    = 0
    }
    tags {
        Name        = "${terraform.workspace}-private-ACL"
        Environment = "${terraform.workspace}"
    }
}

resource "aws_network_acl" "public" {
    vpc_id     = "${aws_vpc.default.id}"
    subnet_ids = ["${aws_subnet.public-app.*.id}"]
    ingress {
        protocol   = "-1"
        rule_no    = 100
        action     = "allow"
        cidr_block = "0.0.0.0/0"
        from_port  = 0
        to_port    = 0
    }
    egress {
        protocol   = "-1"
        rule_no    = 100
        action     = "allow"
        cidr_block = "0.0.0.0/0"
        from_port  = 0
        to_port    = 0
    }
    tags {
        Name        = "${terraform.workspace}-public-ACL"
        Environment = "${terraform.workspace}"
    }
}

resource "aws_network_acl" "bastion" {
    vpc_id     = "${aws_vpc.default.id}"
    subnet_ids = ["${aws_subnet.public-bastion.*.id}"]
    ingress {
        protocol   = "-1"
        rule_no    = 100
        action     = "allow"
        cidr_block = "0.0.0.0/0"
        from_port  = 0
        to_port    = 0
    }
    egress {
        protocol   = "-1"
        rule_no    = 100
        action     = "allow"
        cidr_block = "0.0.0.0/0"
        from_port  = 0
        to_port    = 0
    }
    tags {
        Name        = "${terraform.workspace}-bastions-ACL"
        Environment = "${terraform.workspace}"
    }
}
resource "aws_route53_zone" "internal" {
    name     = "${terraform.workspace}.${var.project}.internal"
    vpc_id   = "${aws_vpc.default.id}"
    comment  = "Zone for ${var.project} in ${terraform.workspace}"
    tags {
        Environment = "${terraform.workspace}"
    }
}
