variable "s3BucketName" {
  default = "project-support"
}
variable "company" {
  default = "Generic"
}
variable "projectTags" {
  type = "map"
  default = {
    Generic = "Generic"
  }
}
