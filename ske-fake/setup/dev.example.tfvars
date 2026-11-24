workspace      = "devops-platform"
payment_method = "testdevops"

project_identifier = "ske-fake-platform-dev"

tags = {
  landingzone        = { confidentiality = ["Internal"], environment = ["dev", "prod", "qa", "test"] }
  project            = { confidentiality = ["Internal"], environment = ["dev"] }
  starterkit_project = { confidentiality = ["Internal"] }
  stages = {
    dev  = { landingzone = { confidentiality = ["Internal"], environment = ["dev"] }, project = { environment = ["dev"] } }
    prod = { landingzone = { confidentiality = ["Internal"], environment = ["prod"] }, project = { environment = ["prod"] } }
  }
}
