resource "random_id" "complete_install" {
  keepers = {
    dependency_on = var.dependency_on
  }

  byte_length = 1

  connection {
    type        = "ssh"
    host        = var.bastion_public_ip
    user        = var.rhel_user
    agent       = false
    timeout     = "30s"
    private_key = var.vm_private_key
  }

  provisioner "file" {
    source      = "${path.module}/scripts/complete-install.sh"
    destination = "${var.setup_dir}/complete-install.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "cd ${var.setup_dir}",
      "chmod +x ${var.setup_dir}/complete-install.sh",
      "${var.setup_dir}/complete-install.sh ${var.setup_dir} ${var.total_nodes}",
    ]
  }
}

resource "camc_scriptpackage" "get_kubeadmin_password" {
  depends_on  = [random_id.complete_install]
  program     = ["cat", "/tmp/ocp-install/auth/kubeadmin-password"]
  on_create   = true
  remote_host = var.bastion_public_ip
  remote_user = var.rhel_user
  remote_key  = base64encode(var.vm_private_key)
}

resource "camc_scriptpackage" "get_kubeconfig" {
  depends_on  = [random_id.complete_install]
  program     = ["cat", "/tmp/ocp-install/auth/kubeconfig"]
  on_create   = true
  remote_host = var.bastion_public_ip
  remote_user = var.rhel_user
  remote_key  = base64encode(var.vm_private_key)
}

