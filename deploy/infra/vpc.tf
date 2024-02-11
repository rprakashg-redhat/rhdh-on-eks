module "vpc" {
    source  = "terraform-aws-modules/vpc/aws"
    version = "5.5.1"

    name = "${var.name}-vpc"

    cidr = local.vpc_cidr
    azs  = local.azs

    private_subnets         = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k)]
    public_subnets          = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 3)]
    database_subnets        = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 6)]
    
    create_database_subnet_group = true
    
    enable_nat_gateway      = true
    single_nat_gateway      = true
    enable_dns_hostnames    = true

    public_subnet_tags = {
        "kubernetes.io/cluster/${var.name}" = "shared"
        "kubernetes.io/role/elb"            = 1
    }

    private_subnet_tags = {
        "kubernetes.io/cluster/${var.name}" = "shared"
        "kubernetes.io/role/internal-elb"    = 1
    }

    tags = local.tags
}