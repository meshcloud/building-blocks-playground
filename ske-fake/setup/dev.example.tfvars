workspace      = "devops-platform"
payment_method = "testdevops"

tags = {
  landingzone        = { confidentiality = ["Internal"] }
  project            = { confidentiality = ["Internal"], environment = ["dev"] }
  starterkit_project = { confidentiality = ["Internal"] }
  stages = {
    dev  = { landingzone = { confidentiality = ["Internal"] }, project = { environment = ["dev"] } }
    prod = { landingzone = { confidentiality = ["Confidential"] }, project = { environment = ["prod"] } }
  }
}
