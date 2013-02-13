# OMF_VERSIONS = 6.0

@comm = OmfEc.comm

# @comm is default communicator defined in script runner
#
@ovs_id = "ovs"
@ovs_topic = @comm.get_topic(@ovs_id)

@switch_id = nil
@switch_topic = nil


msgs = {
  switches: @comm.request_message([:switches]),
  create_switch: @comm.create_message([type: 'virtual_openflow_switch']),
  config_switch_name: @comm.configure_message([name: 'br0']),
  config_add_port: @comm.configure_message([ports: {operation: 'add', name: 'tun0', type: 'tunnel'}]),
  request_port: @comm.request_message([port: {information: 'netdev-tunnel/get-port', name: 'tun0'}]),
  configure_port: @comm.configure_message([port: {name: 'tun0', remote_ip: '138.48.3.201', remote_port: '39505'}]),
}

@ovs_topic.subscribe {msgs[:switches].publish @ovs_id}

# If flowvisor is not raised, the following rule will be activated.
@ovs_topic.on_message lambda {|m| m.operation == :inform && m.read_content('inform_type') == 'CREATION_FAILED' } do |message|
  logger.error message.read_content('reason')
  done!
end

msgs[:switches].on_inform_status do |message|
  logger.info "OVS (#{message.read_property('uid')}) requested switches: #{message.read_property('switches')}"
  msgs[:create_switch].publish @ovs_id
end

msgs[:create_switch].on_inform_creation_ok do |message|
  @switch_id = message.resource_id
  @switch_topic = @comm.get_topic(@switch_id)
 
  msgs[:release_switch] ||= @comm.release_message {|m| m.element('resource_id', @switch_id)}
  msgs[:release_switch].on_inform_released do |message|
    logger.info "Switch (#{@switch_id}) released"
    m = @comm.request_message([:switches])
    m.on_inform_status do |message|
      logger.info "OVS (#{message.read_property('uid')}) requested switches: #{message.read_property('switches')}"
      done!
    end
    m.publish @ovs_id
  end
  
  logger.info "Switch (#{@switch_id}) created"
  @switch_topic.subscribe {msgs[:config_switch_name].publish @switch_id}
end

msgs[:config_switch_name].on_inform_status do |message|
  logger.info "Switch (#{message.read_property('uid')}) configured name: #{message.read_property('name')}"
  msgs[:config_add_port].publish @switch_id
end

msgs[:config_add_port].on_inform_status do |message|
  logger.info "Switch (#{message.read_property('uid')}) configured ports: #{message.read_property('ports')}"
  msgs[:request_port].publish @switch_id
end

msgs[:request_port].on_inform_status do |message|
  logger.info "Switch (#{message.read_property('uid')}) requested port: #{message.read_property('port')}"
  msgs[:configure_port].publish @switch_id
end

msgs[:configure_port].on_inform_status do |message|
  logger.info "Switch (#{message.read_property('uid')}) configured port: #{message.read_property('port')}"
  msgs[:release_switch].publish @ovs_id
end

