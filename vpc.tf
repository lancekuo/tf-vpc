resource "aws_vpc" "default" {
    provider = "aws.${var.region}"
    cidr_block           = "${lookup(var.subnets_map, terraform.env)}"
    enable_dns_support   = true
    enable_dns_hostnames = true
    tags  {
        Name              = "${terraform.env}-${var.project}"
        Env               = "${terraform.env}"
    }
}

resource "aws_internet_gateway" "default" {
    provider = "aws.${var.region}"
    vpc_id = "${aws_vpc.default.id}"
    tags {
        Name              = "${terraform.env}-internet-gateway"
        Env               = "${terraform.env}"
    }
}

resource "aws_nat_gateway" "default" {
    provider = "aws.${var.region}"
    allocation_id = "${aws_eip.nat.id}"
    subnet_id     = "${aws_subnet.private.0.id}"
    depends_on    = ["aws_internet_gateway.default"]
}

resource "aws_eip" "nat" {
    provider = "aws.${var.region}"
    vpc = true
}

resource "aws_default_route_table" "public" {
    provider = "aws.${var.region}"
    default_route_table_id = "${aws_vpc.default.default_route_table_id}"
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.default.id}"
    }
    tags {
        Name              = "public-route"
        Env               = "${terraform.env}"
    }
}

resource "aws_route_table" "private" {
    provider = "aws.${var.region}"
    vpc_id = "${aws_vpc.default.id}"
    route {
        cidr_block     = "0.0.0.0/0"
        nat_gateway_id = "${aws_nat_gateway.default.id}"
    }
    tags {
        Name              = "private-route"
        Env               = "${terraform.env}"
    }
}

resource "aws_subnet" "public" {
    provider = "aws.${var.region}"
    count                   = "${var.subnet-on-public}"
    vpc_id                  = "${aws_vpc.default.id}"
    cidr_block              = "${replace(lookup(var.subnets_map, "${terraform.env}_subnet_template"), "PLACEHOLDER", lookup(var.subnets_map, "bastion_def")+count.index)}"
    availability_zone       = "${element(data.aws_availability_zones.azs.names, count.index)}"
    map_public_ip_on_launch = true
    tags  {
        Name              = "Bastion-${count.index}"
        Env               = "${terraform.env}"
    }
    tags {
    }
}
resource "aws_subnet" "public-app" {
    provider = "aws.${var.region}"
    count                   = "${var.subnet-per-zone*length(data.aws_availability_zones.azs.names)}"
    vpc_id                  = "${aws_vpc.default.id}"
    cidr_block              = "${replace(lookup(var.subnets_map, "${terraform.env}_subnet_template"), "PLACEHOLDER", lookup(var.subnets_map, "app_def")+count.index)}"
    availability_zone       = "${element(data.aws_availability_zones.azs.names, count.index)}"
    map_public_ip_on_launch = true
    tags {
        Name              = "Public-app-${count.index}"
        Env               = "${terraform.env}"
    }
}

resource "aws_subnet" "private" {
    provider = "aws.${var.region}"
    count                   = "${var.subnet-per-zone*length(data.aws_availability_zones.azs.names)}"
    vpc_id                  = "${aws_vpc.default.id}"
    cidr_block              = "${replace(lookup(var.subnets_map, "${terraform.env}_subnet_template"), "PLACEHOLDER", lookup(var.subnets_map, "private_def")+count.index)}"
    availability_zone       = "${element(data.aws_availability_zones.azs.names, count.index)}"
    map_public_ip_on_launch = true
    tags {
        Name              = "Private-${count.index}"
        Env               = "${terraform.env}"
    }
}

resource "aws_route_table_association" "public-route" {
    provider = "aws.${var.region}"
    count = "${var.subnet-on-public}"
    subnet_id      = "${element(aws_subnet.public.*.id, count.index)}"
    route_table_id = "${aws_default_route_table.public.id}"
}

resource "aws_route_table_association" "public-app-route" {
    provider = "aws.${var.region}"
    count = "${var.subnet-per-zone*length(data.aws_availability_zones.azs.names)}"
    subnet_id      = "${element(aws_subnet.public-app.*.id, count.index)}"
    route_table_id = "${aws_default_route_table.public.id}"
}

resource "aws_route_table_association" "private-route" {
    provider = "aws.${var.region}"
    count = "${var.subnet-per-zone*length(data.aws_availability_zones.azs.names)}"
    subnet_id      = "${element(aws_subnet.private.*.id, count.index)}"
    route_table_id = "${aws_route_table.private.id}"
}

resource "aws_route53_zone" "internal" {
    provider = "aws.${var.region}"
    name     = "${var.project}.internal"
    vpc_id   = "${aws_vpc.default.id}"
    tags {
        Environment = "${terraform.env}"
    }
}
