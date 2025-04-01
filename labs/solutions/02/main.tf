terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "3.0.2"
    }
  }
}

provider "docker" {
  host = "tcp://localhost:2375"
}

resource "docker_image" "httpd" {
  name = "httpd:latest"
}

resource "docker_container" "webserver" {
  image = docker_image.httpd.image_id
  name  = "webserver"
  ports {
    internal = 80
    external = 88
  }
}


