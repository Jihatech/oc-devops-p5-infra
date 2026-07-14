# Exercice 1 - Partie Terraform (option Docker local)
# Objectif : provisionner un conteneur Nginx via Infrastructure-as-Code.
# Le port 80 du conteneur est exposé sur le port 8000 de l'hôte.

terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "3.0.2"
    }
  }
}

# Provider Docker : pilote le démon Docker local (Docker Desktop).
provider "docker" {}

# Récupère (pull) l'image officielle nginx:latest depuis Docker Hub.
resource "docker_image" "nginx" {
  name         = "nginx:latest"
  keep_locally = true
}

# Instancie un conteneur à partir de l'image ci-dessus.
resource "docker_container" "nginx" {
  name  = "oc-p5-nginx"
  image = docker_image.nginx.image_id

  # Mappe le port 80 (interne au conteneur) sur le port 8000 de la machine hôte.
  ports {
    internal = 80
    external = 8000
  }
}

# Affiche l'URL d'accès après apply (réflexe de sortie utile).
output "url_application" {
  value       = "http://localhost:8000"
  description = "URL d'accès au serveur Nginx déployé par Terraform."
}
