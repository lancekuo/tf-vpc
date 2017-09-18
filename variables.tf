provider "aws" {
    alias   = "${var.aws_region}"
    region  = "${var.aws_region}"
    profile = "${var.aws_profile}"
}
data "aws_availability_zones" "azs" {
    provider = "aws.${var.aws_region}"
}

variable "aws_region"                     {}
variable "aws_profile"                    {}
variable "project"                        {}
variable "count_bastion_subnet_on_public" {}
variable "count_public_subnet_per_az"     {}
variable "count_private_subnet_per_az"    {}

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
