# OMF_VERSIONS = 6.0

def create_switch(ovs)
  ovs.create(:virtual_openflow_switch, {name: "test"}) do |reply_msg|
    if reply_msg.success?
      switch = reply_msg.resource

      switch.on_subscribed do
        info ">>> Connected to newly created switch #{reply_msg[:res_id]} with name #{reply_msg[:name]}"
        on_switch_created(switch)
      end

      after(10) do
        ovs.release(switch) do |reply_msg|
          info ">>> Released switch #{reply_msg[:res_id]}"
        end
      end
    else
      error ">>> Switch creation failed - #{reply_msg[:reason]}"
    end
  end
end

def on_switch_created(switch)

  switch.configure(ports: {operation: 'add', name: 'tun0', type: 'tunnel'}) do |reply_msg|
    info "> Switch configured ports: #{reply_msg[:ports]}"
    switch.request([:tunnel_port_numbers]) do |reply_msg|
      info "> Switch requested tunnel port: #{reply_msg[:tunnel_port_numbers]}"
      switch.configure(tunnel_port: {name: 'tun0', remote_ip: '127.0.0.1', remote_port: '1234'}) do |reply_msg|
        info "> Switch configured tunnel port: #{reply_msg[:tunnel_port]}"
      end
    end
  end

  # Monitor all status, error or warn information from the switch
  #switch.on_status do |msg|
  #  msg.each_property do |name, value|
  #    info "#{name} => #{value}"
  #  end
  #end
  switch.on_error do |msg|
    error msg[:reason]
  end
  switch.on_warn do |msg|
    warn msg[:reason]
  end
end

OmfCommon.comm.subscribe('ovs') do |ovs|
  unless ovs.error?
    create_switch(ovs)
  else
    error ovs.inspect
  end

  after(20) { info 'Disconnecting ...'; OmfCommon.comm.disconnect }
end
