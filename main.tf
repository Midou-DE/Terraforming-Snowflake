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
