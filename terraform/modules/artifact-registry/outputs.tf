output "repository_id" {
  description = "Repository ID"
  value       = google_artifact_registry_repository.registry.repository_id
}

output "repository_url" {
  description = "Repository URL for docker push/pull"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.registry.repository_id}"
}