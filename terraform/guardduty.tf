# =============================================================================
# GuardDuty — Intelligent Threat Detection
# =============================================================================
# DISABLED: Service Control Policy prevents deletion
# Resource exists but is not managed by Terraform
# =============================================================================

# resource "aws_guardduty_detector" "main" {
#   enable = true
#   finding_publishing_frequency = "FIFTEEN_MINUTES"
#   datasources {
#     s3_logs {
#       enable = true
#     }
#     kubernetes {
#       audit_logs {
#         enable = false
#       }
#     }
#     malware_protection {
#       scan_ec2_instance_with_findings {
#         ebs_volumes {
#           enable = true
#         }
#       }
#     }
#   }
#   tags = merge(
#     local.common_tags,
#     {
#       Name    = "notes-app-guardduty"
#       Purpose = "Threat detection"
#     }
#   )
# }
