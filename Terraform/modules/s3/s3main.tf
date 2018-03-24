resource "aws_s3_bucket" "projectSupport" {
  # NOTE: S3 bucket names must be unique across _all_ AWS accounts, so
  # this name must be changed before applying this example to avoid naming
  # conflicts.
  bucket = "${var.s3BucketName}"
  acl    = "private"
  tags = "${merge(
    var.projectTags,
    map(
      "Company", "${var.company}",
      "Source", "Terraform s3 Module",
      "AnotherTag","ATagValue"
    )
  )}"
}

resource "aws_cloudwatch_metric_alarm" "s3BucketAlarm" {
  alarm_name                = "terraform-s3Bucket-Alarm"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "1"
  metric_name               = "BucketSizeBytes"
  namespace                 = "AWS/S3"
  period                    = "86400"
  statistic                 = "Average"
  threshold                 = "80"
  alarm_description         = "This metric monitors s3 Bucket Size"
  insufficient_data_actions = []
  dimensions {
     BucketName = "${aws_s3_bucket.projectSupport.id}"
     StorageType = "StandardStorage"
  }
}

