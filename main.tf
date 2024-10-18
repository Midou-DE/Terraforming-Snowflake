# Define the Terraform configuration
terraform {
  # Specify the required provider for the configuration
  required_providers {
    # Using the Snowflake provider, sourced from Snowflake Labs
    snowflake = {
      source  = "Snowflake-Labs/snowflake"  # The provider source
      version = "~> 0.87"                   # Provider version, compatible with versions 0.87.x
    }
  }
}

# Configure the Snowflake provider
provider "snowflake" {
  # Set the role that Terraform will assume when interacting with Snowflake
  role = "SYSADMIN"  # The SYSADMIN role has administrative privileges for creating resources
}

# Create a Snowflake database resource
resource "snowflake_database" "db" {
  # Name of the database to be created
  name = "TF_DEMO"  # This database will be named "TF_DEMO"
}

# Create a Snowflake warehouse resource
resource "snowflake_warehouse" "warehouse" {
  # Name of the warehouse to be created
  name           = "TF_DEMO"      # The warehouse will also be named "TF_DEMO"
  
  # Define the size of the warehouse (XS = Extra Small)
  warehouse_size = "xsmall"       # The warehouse will be of size "xsmall" (suitable for small workloads)
  
  # Configure the auto-suspend time for the warehouse (in minutes)
  auto_suspend   = 60             # The warehouse will automatically suspend after 60 minutes of inactivity
}

provider "snowflake" {
  alias = "security_admin"
  role  = "SECURITYADMIN"
}

resource "snowflake_role" "role" {
  provider = snowflake.security_admin
  name     = "TF_DEMO_SVC_ROLE"
}

resource "snowflake_grant_privileges_to_account_role" "database_grant" {
  provider          = snowflake.security_admin
  privileges        = ["USAGE"]
  account_role_name = snowflake_role.role.name
  on_account_object {
    object_type = "DATABASE"
    object_name = snowflake_database.db.name
  }
}

resource "snowflake_schema" "schema" {
  database   = snowflake_database.db.name
  name       = "TF_DEMO"
  is_managed = false
}

resource "snowflake_grant_privileges_to_account_role" "schema_grant" {
  provider          = snowflake.security_admin
  privileges        = ["USAGE"]
  account_role_name = snowflake_role.role.name
  on_schema {
    schema_name = "\"${snowflake_database.db.name}\".\"${snowflake_schema.schema.name}\""
  }
}

resource "snowflake_grant_privileges_to_account_role" "warehouse_grant" {
  provider          = snowflake.security_admin
  privileges        = ["USAGE"]
  account_role_name = snowflake_role.role.name
  on_account_object {
    object_type = "WAREHOUSE"
    object_name = snowflake_warehouse.warehouse.name
  }
}

resource "tls_private_key" "svc_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "snowflake_user" "user" {
    provider          = snowflake.security_admin
    name              = "tf_demo_user"
    default_warehouse = snowflake_warehouse.warehouse.name
    default_role      = snowflake_role.role.name
    default_namespace = "${snowflake_database.db.name}.${snowflake_schema.schema.name}"
    rsa_public_key    = substr(tls_private_key.svc_key.public_key_pem, 27, 398)
}

resource "snowflake_grant_privileges_to_account_role" "user_grant" {
  provider          = snowflake.security_admin
  privileges        = ["MONITOR"]
  account_role_name = snowflake_role.role.name  
  on_account_object {
    object_type = "USER"
    object_name = snowflake_user.user.name
  }
}

resource "snowflake_grant_account_role" "grants" {
  provider  = snowflake.security_admin
  role_name = snowflake_role.role.name
  user_name = snowflake_user.user.name
}