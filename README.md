# OmfRcOpenflow

This package includes OMF6 Resource Controllers (RCs) related to the OpenFlow technology.
The OMF6 framework considers everything (hardware, software, etc) as a separate resource.
This version includes the RCs of the Stanford software tools, named FlowVisor and OpenvSwitch.

* FlowVisor creates OpenFlow Slices (slicing the flow space into separate pieces), so the corresponding RC is the OpenFlow_Slice_Factory.
* OpenvSwitch creates Virtual OpenFlow Switches on top of a Linux machine using the machine's interfaces, so the corresponding RC is the Virtual_OpenFlow_Switch_Factory.

## Installation

Add this line to your application's Gemfile:

    gem 'omf_rc_openflow'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install omf_rc_openflow

## Usage

In a Linux machine that runs FlowVisor or OpenvSwitch software, execute:

    $ omf_rc_openflow_slice_factory -u xmpp://user:password@domain -i topic

Or execute:

    $ omf_rc_virtual_openflow_slice_factory -u xmpp://user:password@domain -i topic

to control the FlowVisor or OpenvSwitch resource in a OMF6 Experiment Controller (EC).

The 'example' subdirectory includes some examples of experiment descriptions, that could be feeded to the omf_ec binary (the OMF6 EC)


