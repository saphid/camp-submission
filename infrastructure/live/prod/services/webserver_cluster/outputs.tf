output "clb_dns_name" {
  value       = module.webserver_cluster.url
  description = "The url of the new web cluster"
}
