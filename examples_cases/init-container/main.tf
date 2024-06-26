resource "azurerm_resource_group" "test" {
  location = var.location
  name     = "rg-terratest-initcontainer-${var.resource_suffix}-${random_id.rg_name.hex}"
}


module "container_apps" {
  source                         = "../.."
  resource_group_name            = azurerm_resource_group.test.name
  location                       = var.location
  container_app_environment_name = "cae-${var.resource_suffix}-${random_id.env_name.hex}"

  container_apps = {
    example = {
      name          = "example-ca-${random_id.container_name.hex}"
      revision_mode = "Single"

      template = {
        init_containers = [
          {
            name   = "debian"
            image  = "debian:latest"
            memory = "0.5Gi"
            cpu    = 0.25
            command = [
              "/bin/sh",
            ]
            args = [
              "-c", "echo Hello from the debian container > /shared/index.html"
            ]
            volume_mounts = [
              {
                name = "shared"
                path = "/shared"
              }
            ]
          }
        ],
        containers = [
          {
            name   = "nginx"
            image  = "nginx:latest"
            memory = "1Gi"
            cpu    = 0.5
            volume_mounts = [{
              name = "shared"
              path = "/usr/share/nginx/html"
            }]
          }
        ],
        volume = [
          {
            name         = "shared"
            storage_type = "EmptyDir"
          }
        ]
      }


      ingress = {
        allow_insecure_connections = false
        target_port                = 80
        external_enabled           = true

        traffic_weight = {
          latest_revision = true
          percentage      = 100
        }
      }
    },
  }
}
