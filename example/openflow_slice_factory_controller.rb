#!/usr/bin/env ruby

require 'omf_rc'
require 'omf_rc/resource_factory'
$stdout.sync = true

Blather.logger = logger

opts = {
  # XMPP server domain
  server: 'srv.mytestbed.net', # 'localhost',
  # Debug mode of not
  debug: false
}

Logging.logger.root.level = :debug if opts[:debug]

OmfRc::ResourceFactory.load_addtional_resource_proxies("../lib/omf_rc/resource_proxy")

EM.run do
  # Use resource factory method to initialise a new instance of garage
  g = "flowvisor"
  info "Starting #{g}"
  flowvisor = OmfRc::ResourceFactory.new(
    :openflow_slice_factory,
    opts.merge(user: g, password: 'pw', uid: g)
  )
  flowvisor.connect

  # Disconnect garage from XMPP server, when these two signals received
  trap(:INT) { flowvisor.disconnect }
  trap(:TERM) { flowvisor.disconnect }
end
