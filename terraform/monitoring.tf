resource "datadog_monitor" "application_http" {
  name = "[project-77] Application HTTP check failed"
  type = "service check"

  query = "\"http.can_connect\".over(\"env:production\",\"service:project-77\").by(\"host\").last(2).count_by_status()"

  message = <<-EOT
    The application did not answer the local HTTP check on {{host.name}}.
    Check the project-77-web container and the web server logs.
  EOT

  tags         = ["project:hexlet-77", "env:production", "managed-by:terraform"]
  include_tags = true

  notify_no_data    = true
  no_data_timeframe = 5

  monitor_thresholds {
    ok       = 1
    warning  = 1
    critical = 2
  }
}
