module "health_check" {
  source            = "./modules/health_check"
  name              = format("%s-class-health-check-tf", var.name)
  namespace         = var.namespace
  health_check_path = var.health_check_path
}

module "ip_origin_pool" {
  source                   = "./modules/origin_pool"
  name                     = format("%s-pool-tf", var.name)
  origin_pool_port         = var.ip_origin_pool_port
  origin_pool_service_name = var.origin_pool_service_name
  origin_pool_virtual_site = var.origin_pool_virtual_site
  health_check_name        = module.health_check.health_check_name
  namespace                = var.namespace
}

module "load_balancer" {
  source      = "./modules/load_balancer"
  name        = format("%s-lb-tf", var.name)
  origin_pool = module.ip_origin_pool.name
  domains     = var.domains
  namespace   = var.namespace
  http_port   = var.http_port
  depends_on  = [module.ip_origin_pool]
}

variable "site_name" {
  type = string
}

variable "aws_access_key" {
  type = string
}

variable "b64_aws_secret_key" {
  type = string
}

variable "aws_region" {
  type    = string
  default = "ap-southeast-1"
}

variable "aws_vpc_cidr" {
  default = "192.168.0.0/20"
}

variable "aws_az" {
  type    = string
  default = "ap-southeast-1a"
}

variable "outside_subnet_cidr_block" {
  type    = string
  default = "192.168.0.0/25"
}

resource "volterra_cloud_credentials" "aws_cred" {
  name      = format("tsanghan-%s-cred", var.site_name)
  namespace = "system"
  aws_secret_key {
    access_key = var.aws_access_key
    secret_key {
      clear_secret_info {
        url = format("string:///%s", var.b64_aws_secret_key)
      }
    }
  }
}

resource "volterra_aws_vpc_site" "site" {
  name       = var.site_name
  namespace  = "system"
  aws_region = var.aws_region
  disk_size  = "80"

  # block_all_services = true
  blocked_services {
    blocked_sevice {
      dns                = false
      ssh                = false
      web_user_interface = true
    }

  }
  enable_internet_vip     = true
  direct_connect_disabled = true
  egress_gateway_default  = true
  f5_orchestrated_routing = true
  f5xc_security_group     = true

  ssh_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIISLxyrw7SGaqlZdZHjVrjTv1k/Q48OWiz6rrhY/BHtc tsanghan"

  aws_cred {
    name      = volterra_cloud_credentials.aws_cred.name
    namespace = "system"
  }

  instance_type = "m5.4xlarge"

  vpc {
    new_vpc {
      name_tag     = var.site_name
      primary_ipv4 = var.aws_vpc_cidr
    }
  }

  ingress_gw {
    allowed_vip_port {
      use_http_https_port = true
    }
    aws_certified_hw = "aws-byol-voltmesh"
    az_nodes {
      aws_az_name = var.aws_az
      local_subnet {
        subnet_param {
          ipv4 = var.outside_subnet_cidr_block
        }
      }
    }
    performance_enhancement_mode {
      perf_mode_l7_enhanced = true
    }

  }
  no_worker_nodes         = true
  logs_streaming_disabled = true
}

resource "volterra_tf_params_action" "apply_aws_vpc" {
  site_name        = volterra_aws_vpc_site.site.name
  site_kind        = "aws_vpc_site"
  action           = "apply"
  wait_for_action  = true
  ignore_on_update = true
}
