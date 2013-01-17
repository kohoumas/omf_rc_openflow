# OMF_VERSIONS = 6.0

@comm = OmfEc.comm

# @comm is default communicator defined in script runner
#
flowvisor_id = "flowvisor"
flowvisor_topic = @comm.get_topic(flowvisor_id)

flowvisor_topic.on_message lambda {|m| m.operation == :inform && m.read_content('inform_type') == 'CREATION_FAILED' } do |message|
  logger.error message
end

msgs = {
  create: @comm.create_message([type: 'openflow_slice', name: 'test1']),
  request: @comm.request_message([:flows]),
}

%w{request}.each do |s|
  msgs[s.to_sym].on_inform_status do |message|
    message.each_property do |p|
      logger.info "#{p.attr('key')} => #{p.content.strip}"
    end
  end
end

msgs[:create].on_inform_creation_failed do |message|
  logger.error "Resource creation failed ---"
  logger.error message.read_content("reason")
end

msgs[:create].on_inform_creation_ok do |message|
  slice_topic = @comm.get_topic(message.resource_id)
  slice_id = slice_topic.id

  msgs[:release] ||= @comm.release_message { |m| m.element('resource_id', slice_id) }

  msgs[:release].on_inform_released do |message|
    logger.info "Slice (#{message.resource_id}) deleted (resource released)"
    done!
  end

  logger.info "Slice #{slice_id} ready for testing"

  slice_topic.subscribe do
    msgs[:request].publish slice_id
  end
end

flowvisor_topic.subscribe do
  msgs[:create].publish flowvisor_topic.id
end
