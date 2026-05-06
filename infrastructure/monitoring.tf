locals {
  uptime_targets = {
    root = {
      host = var.domain_name
      path = "/"
    }
    app = {
      host = "app.${var.domain_name}"
      path = "/"
    }
    relay = {
      host = "relay.${var.domain_name}"
      path = "/"
    }
    mcp = {
      host = "ai.${var.domain_name}"
      path = "/health"
    }
  }
}

resource "google_monitoring_uptime_check_config" "https" {
  for_each = local.uptime_targets

  project      = var.project_id
  display_name = "${local.project_base_name}-${each.key}-https"
  timeout      = "10s"
  period       = "60s"

  selected_regions = [
    "USA",
    "SOUTH_AMERICA",
    "EUROPE",
  ]

  http_check {
    path           = each.value.path
    port           = 443
    request_method = "GET"
    use_ssl        = true
    validate_ssl   = true
  }

  monitored_resource {
    type = "uptime_url"
    labels = {
      project_id = var.project_id
      host       = each.value.host
    }
  }

  depends_on = [google_project_service.monitoring]
}

resource "google_monitoring_notification_channel" "uptime_email" {
  for_each = toset(var.uptime_alert_email_channels)

  project      = var.project_id
  display_name = "Uptime alerts: ${each.value}"
  type         = "email"
  enabled      = true

  labels = {
    email_address = each.value
  }

  depends_on = [google_project_service.monitoring]
}

resource "google_monitoring_alert_policy" "uptime_failed" {
  for_each = google_monitoring_uptime_check_config.https

  project      = var.project_id
  display_name = "${local.project_base_name}-${each.key}-uptime-failed"
  combiner     = "OR"
  enabled      = true
  severity     = "ERROR"

  notification_channels = [
    for channel in google_monitoring_notification_channel.uptime_email :
    channel.name
  ]

  conditions {
    display_name = "${local.project_base_name}-${each.key} HTTPS uptime failed"

    condition_threshold {
      filter = join(" AND ", [
        "resource.type = \"uptime_url\"",
        "metric.type = \"monitoring.googleapis.com/uptime_check/check_passed\"",
        "metric.label.check_id = \"${each.value.uptime_check_id}\"",
      ])

      duration        = "120s"
      comparison      = "COMPARISON_LT"
      threshold_value = 1

      aggregations {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_FRACTION_TRUE"
        cross_series_reducer = "REDUCE_MIN"
        group_by_fields      = ["metric.label.check_id"]
      }
    }
  }

  documentation {
    mime_type = "text/markdown"
    content   = "`${each.value.display_name}` failed from at least one Cloud Monitoring uptime region for 2 minutes. Check container state, nginx logs, GCP audit logs, and VPC flow logs to distinguish origin failure from network-path reachability."
  }

  alert_strategy {
    auto_close = "1800s"
  }
}
