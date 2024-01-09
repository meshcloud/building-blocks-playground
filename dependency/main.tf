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

output "file" {
  value = {
    note            = "This is a test branch"
    filename        = local_file.dependency.filename
    file_permissons = local_file.dependency.file_permission
  }
}
