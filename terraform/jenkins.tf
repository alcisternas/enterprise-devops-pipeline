module "jenkins_vm" {
  source = "./modules/compute"

  project_id    = var.project_id
  instance_name = "jenkins-server"
  machine_type  = "e2-medium"
  zone          = "${var.region}-a"
  disk_size_gb  = 30

  network_tags    = ["jenkins", "http-server"]
  create_firewall = true

  startup_script = "#!/bin/bash\nset -e\napt-get update\napt-get install -y podman\nmkdir -p /opt/jenkins_home\nchown -R 1000:1000 /opt/jenkins_home\npodman run -d --name jenkins --restart=always -p 8080:8080 -p 50000:50000 -v /opt/jenkins_home:/var/jenkins_home docker.io/jenkins/jenkins:lts\necho 'Jenkins started on port 8080'"
}

output "jenkins_external_ip" {
  description = "Jenkins server external IP"
  value       = module.jenkins_vm.external_ip
}

output "jenkins_url" {
  description = "Jenkins URL"
  value       = "http://${module.jenkins_vm.external_ip}:8080"
}