resource "azurerm_resource_group" "test" {
  location = var.location
  name     = "rg-terratest-startup-${var.resource_suffix}-${random_id.rg_name.hex}"
}

module "container_apps" {
  source                         = "../.."
  resource_group_name            = azurerm_resource_group.test.name
  location                       = var.location
  container_app_environment_name = "cae-${var.resource_suffix}-${random_id.env_name.hex}"

  container_apps = {
    counting = {
      name          = local.counting_app_name
      revision_mode = "Single"

      template = {
        containers = [
          {
            name   = "countingservicetest1"
            memory = "0.5Gi"
            cpu    = 0.25
            image  = "docker.io/hashicorp/counting-service:0.0.2"
            env = [
              {
                name  = "PORT"
                value = "9001"
              }
            ]
          },
        ]
      }

      ingress = {
        allow_insecure_connections = true
        external_enabled           = true
        target_port                = 9001
        traffic_weight = {
          latest_revision = true
          percentage      = 100
        }
      }
    },
    dashboard = {
      name          = local.dashboard_app_name
      revision_mode = "Single"

      template = {
        containers = [
          {
            name   = "testdashboard"
            memory = "1Gi"
            cpu    = 0.5
            image  = "docker.io/hashicorp/dashboard-service:0.0.4"
            env = [
              {
                name  = "PORT"
                value = "8080"
              },
              {
                name  = "COUNTING_SERVICE_URL"
                value = "http://${local.counting_app_name}"
              }
            ]
          },
        ]
      }

      ingress = {
        allow_insecure_connections = false
        target_port                = 8080
        external_enabled           = true

        traffic_weight = {
          latest_revision = true
          percentage      = 100
        }
      }
      identity = {
        type = "SystemAssigned"
      }
    },
  }
}
