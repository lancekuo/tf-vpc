provider "aws" {
    alias = "${var.region}"
    region = "${var.region}"
}
variable "region" {}
variable "project" {
    default = "default"
}
variable "subnet-on-public" {
    default = 1
}
variable "subnet-per-zone" {
    default = 1
}
variable "instance-per-subnet" {
    default = 2
}
variable "swarm-manager-count" {
    default = 2
}
variable "swarm-node-count" {
    default = 1
}

data "aws_availability_zones" "azs" {
    provider = "aws.${var.region}"
}
variable "subnets_map" {
    type    = "map"
    default = {
        dev                                     = "10.1.0.0/16"
        dev_subnet_template                     = "10.1.PLACEHOLDER.0/24"
        dev_section_template                    = "10.1.PLACEHOLDER.0/23"
        qa                                      = "10.2.0.0/16"
        qa_subnet_template                      = "10.2.PLACEHOLDER.0/24"
        qa_section_template                     = "10.2.PLACEHOLDER.0/23"
        stg                                     = "10.3.0.0/16"
        stg_subnet_template                     = "10.3.PLACEHOLDER.0/24"
        stg_section_template                    = "10.3.PLACEHOLDER.0/23"
        prd                                     = "10.10.0.0/16"
        prd_subnet_template                     = "10.10.PLACEHOLDER.0/24"
        prd_section_template                    = "10.10.PLACEHOLDER.0/23"
        continuous-integration                  = "192.168.0.0/16"
        continuous-integration_subnet_template  = "192.168.PLACEHOLDER.0/24"
        continuous-integration_section_template = "192.168.PLACEHOLDER.0/23"
        bastion_def                             = 1
        app_def                                 = 10
        private_def                             = 60
    }
}
