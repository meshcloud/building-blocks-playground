workspace      = "devops-platform"
payment_method = "testdevops"

project_identifier = "ske-fake-platform-dev"

tags = {
  landingzone        = { confidentiality = ["Internal"] }
  project            = { confidentiality = ["Internal"], environment = ["dev"] }
  starterkit_project = { confidentiality = ["Internal"] }
  stages = {
    dev  = { landingzone = { confidentiality = ["Internal"] }, project = { environment = ["dev"] } }
    prod = { landingzone = { confidentiality = ["Internal"] }, project = { environment = ["prod"] } }
  }
}
