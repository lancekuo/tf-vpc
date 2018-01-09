resource "aws_vpc" "default" {
    cidr_block           = "${lookup(var.subnets_map, terraform.workspace)}"
    enable_dns_support   = true
    enable_dns_hostnames = true
    tags  {
        Name = "${terraform.workspace}-${var.project}"
        Env  = "${terraform.workspace}"
    }
}

resource "aws_internet_gateway" "default" {
    vpc_id   = "${aws_vpc.default.id}"
    tags {
        Name = "${terraform.workspace}-internet-gateway"
        Env  = "${terraform.workspace}"
    }
}

resource "aws_nat_gateway" "default" {
    count         = "${var.count_private_subnet_per_az > 0 ? 1 : 0}"
    allocation_id = "${aws_eip.nat.id}"
    subnet_id     = "${aws_subnet.private.0.id}"
    depends_on    = ["aws_internet_gateway.default"]
}

resource "aws_eip" "nat" {
    vpc      = true
}

resource "aws_default_route_table" "public" {
    default_route_table_id = "${aws_vpc.default.default_route_table_id}"
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.default.id}"
    }
    tags {
        Name = "public-route"
        Env  = "${terraform.workspace}"
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
        Name = "private-route"
        Env  = "${terraform.workspace}"
    }
}

resource "aws_subnet" "public-bastion" {
    count                   = "${var.count_bastion_subnet_on_public}"
    vpc_id                  = "${aws_vpc.default.id}"
    cidr_block              = "${replace(lookup(var.subnets_map, "${terraform.workspace}_subnet_template"), "PLACEHOLDER", lookup(var.subnets_map, "bastion_def")+count.index)}"
    availability_zone       = "${element(data.aws_availability_zones.azs.names, count.index)}"
    map_public_ip_on_launch = true
    tags  {
        Name = "Public-Bastion-${count.index}"
        Env  = "${terraform.workspace}"
    }
}
resource "aws_subnet" "public-app" {
    count                   = "${var.count_public_subnet_per_az*length(data.aws_availability_zones.azs.names)}"
    vpc_id                  = "${aws_vpc.default.id}"
    cidr_block              = "${replace(lookup(var.subnets_map, "${terraform.workspace}_subnet_template"), "PLACEHOLDER", lookup(var.subnets_map, "app_def")+count.index)}"
    availability_zone       = "${element(data.aws_availability_zones.azs.names, count.index)}"
    map_public_ip_on_launch = true
    tags {
        Name = "Public-app-${count.index}"
        Env  = "${terraform.workspace}"
    }
}

resource "aws_subnet" "private" {
    count                   = "${var.count_private_subnet_per_az*length(data.aws_availability_zones.azs.names)}"
    vpc_id                  = "${aws_vpc.default.id}"
    cidr_block              = "${replace(lookup(var.subnets_map, "${terraform.workspace}_subnet_template"), "PLACEHOLDER", lookup(var.subnets_map, "private_def")+count.index)}"
    availability_zone       = "${element(data.aws_availability_zones.azs.names, count.index)}"
    map_public_ip_on_launch = false
    tags {
        Name = "Private-${count.index}"
        Env  = "${terraform.workspace}"
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

resource "aws_route53_zone" "internal" {
    name     = "${var.project}.internal"
    vpc_id   = "${aws_vpc.default.id}"
    tags {
        Environment = "${terraform.workspace}"
    }
}
