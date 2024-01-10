variable "filename" {
  type        = string
  description = "a name for the file (without extension)"
}

variable "content" {
  type        = string
  description = "Text that will be content of the created file"
}

resource "local_file" "dependency" {
  content  = var.content
  filename = "${path.module}/${var.filename}-dependency.txt"
}

resource "time_sleep" "wait_70_minutes" {
  depends_on = [local_file.dependency]

  create_duration = "70m"
}

resource "local_file" "dependency_next" {
  content    = "${var.content}-next"
  filename   = "${path.module}/${var.filename}-dependency-next.txt"
  depends_on = [time_sleep.wait_70_minutes]
}

output "file" {
  value = {
    filename        = local_file.dependency.filename
    file_permissons = local_file.dependency.file_permission
    filename2       = local_file.dependency_next.filename
  }
}
