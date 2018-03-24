variable "s3BucketName" {
  default = "splunk-support"
}

variable "projectTags" {
  type = "map"
  default = {
    Project = "SplunkInABox",
    Client = "iMac27Inch"
  }
}