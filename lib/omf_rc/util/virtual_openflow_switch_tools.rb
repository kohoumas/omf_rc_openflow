module OmfRc::Util::VirtualOpenflowSwitchTools
  include OmfRc::ResourceProxyDSL

  # Internal function that returns a hash result of the json-request to the ovsdb-server or the ovs-switchd instances
  work :ovs_connection do |resource, target, arguments|
    stream = nil
    if target == "ovsdb-server"
      if resource.property.ovs_connection_args.ovsdb_server_conn == "tcp"
        stream = TCPSocket.new(resource.property.ovs_connection_args.ovsdb_server_host, 
                               resource.property.ovs_connection_args.ovsdb_server_port)
      elsif resource.property.ovs_connection_args.ovsdb_server_conn == "unix"
        stream = UNIXSocket.new(resource.property.ovs_connection_args.ovsdb_server_socket)
      end
    elsif target == "ovs-vswitchd"
      if resource.property.ovs_connection_args.ovs_vswitchd_conn == "unix"
        file = File.new(resource.property.ovs_connection_args.ovs_vswitchd_pid, "r")
        pid = file.gets.chomp
        file.close
        socket = resource.property.ovs_connection_args.ovs_vswitchd_socket % [pid]
        stream = UNIXSocket.new(socket)
      end
    end
    stream.puts(arguments.to_json)
    string = stream.gets('{')
    counter = 1 # number of read '['
    while counter > 0
      char = stream.getc
      if char == '{'
        counter += 1
      elsif char == '}'
        counter -= 1
      end
      string += char
    end
    stream.close
    JSON.parse(string)
  end

  # Internal function that returns the switch ports with interfaces of the specified type, if this type is given
  work :ports do |resource, type = nil|
    arguments = {
      "method" => "transact", 
      "params" => [ "Open_vSwitch", 
                    { "op" => "select", 
                      "table" => "Bridge", 
                      "where" => [["name", "==", resource.property.name]], 
                      "columns" => ["ports"]
                    },
                    { "op" => "select", 
                      "table" => "Port", 
                      "where" => [], 
                      "columns" => ["name", "_uuid"]
                    }
                  ],
      "id" => "ports"
    }
    if type
      arguments["params"] << { "op" => "select", 
                               "table" => "Interface", 
                               "where" => [["type", "==", type.to_s]], 
                               "columns" => ["name"]
                             }
    end
    result = resource.ovs_connection("ovsdb-server", arguments)["result"]
    uuid2name = Hashie::Mash.new(Hash[result[1]["rows"].map {|h| [h["_uuid"][1], h["name"]]}]) # hash-table port uuid=>name
    uuids = result[0]["rows"][0]["ports"][1].map {|a| a[1]} # The uuids of the switch ports
    ports = uuids.map {|v| uuid2name[v]} # The names of the switch ports
    if type
      ports_of_type = result[2]["rows"].map {|h| h["name"]} # The names of the ports with interfaces of the specified type
      ports = ports & ports_of_type # The names of the switch ports with interfaces of the specified type
    end
    ports
  end
end
