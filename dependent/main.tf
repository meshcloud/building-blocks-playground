variable "filename" {
  type        = string
  description = "a name for the file (without extension)"
}

variable "content" {
  type        = string
  description = "Text that will be content of the created file"
}

resource "local_file" "dependent" {
  content  = var.content
  filename = "${path.module}/${var.filename}-dependent.txt"
}

output "file" {
  value = {
    filename        = local_file.dependent.filename
    file_permissons = local_file.dependent.file_permission
    content         = local_file.dependent.content
  }
}
