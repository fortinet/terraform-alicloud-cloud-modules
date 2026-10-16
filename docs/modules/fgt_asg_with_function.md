# Module: FGT ASG with Function

This module deploys a FortiGate Auto Scaling group and a Gateway Load Balancer (GWLB), with Function Compute managing the FortiGate instance lifecycle.

This module supports a single Alibaba Cloud region with one or more zones.

This module is intended to be used by higher-level examples. See [cen_tr_gwlb_fgt](../examples/cen_tr_gwlb_fgt.md) for a complete multi-zone deployment.

We recommend using a higher-level example unless you are familiar with this module's configuration and behavior.

## Note
- Not all regions support GWLB, please check [here](https://www.alibabacloud.com/help/en/slb/gateway-based-load-balancing-gwlb/product-overview/regions-and-zones-supported-by-gwlb) for the supported regions.
- When multiple ENIs are configured, only `port1` is created automatically when the FortiGate instance launches. The function creates and attaches ENIs for all other configured ports during instance startup.
- During `terraform destroy`, VSwitch or security group deletion may fail with `DeleteVSwitch Failed` or `DeleteSecurityGroup Failed` because ENIs managed by Alibaba Cloud for Function Compute are still attached. These ENIs are not managed by this Terraform project. Wait for Alibaba Cloud to remove them, then run `terraform destroy` again.


## Deployment Prerequisites

- Activate Message Service, Object Storage Service, Auto Scaling, CloudMonitor, Function Compute, and Tablestore.
- Activate Simple Log Service when `function_compute.logging_level` is not `"NONE"`.
- Confirm that the cloud services used in your deployment and the selected ECS instance type are available in every configured zone.

## Zones and Interfaces

FortiGate instances can run in one or more zones, with one or more network interfaces. The zone count and interface count are independent.

### Single Zone

Set one zone in each interface's `vswitch_ids` map:

```hcl
vswitch_ids = {
  ap-northeast-1a = "vsw-inspection-a"
}
```

All FortiGate instances are created in that zone.

### Multiple Zones

Set multiple zones in each interface's `vswitch_ids` map:

```hcl
vswitch_ids = {
  ap-northeast-1a = "vsw-inspection-a"
  ap-northeast-1c = "vsw-inspection-c"
}
```

The Auto Scaling group uses the `BALANCE` policy to distribute FortiGate instances across these zones. Actual placement depends on instance count and available capacity. Every interface must list the same zones, using the appropriate VSwitch for each interface and zone.

### Single Interface

Define only `port1` in `network.interfaces`:

```hcl
network = {
  interfaces = {
    port1 = {
      vswitch_ids = {
        ap-northeast-1a = "vsw-inspection-a"
      }
      security_group_id = "sg-xxxxxxxx"
    }
  }
}
```

`port1` handles management traffic, communication with Function Compute, and HA synchronization between FortiGate instances. In a GWLB deployment, it also carries Geneve inspection traffic. `ha_sync_interface` defaults to `port1` and can be omitted.

### Multiple Interfaces

Define consecutive interfaces from `port1` through `portN` and select the HA synchronization interface:

```hcl
network = {
  interfaces = {
    port1 = {
      vswitch_ids = {
        ap-northeast-1a = "vsw-inspection-a"
      }
      security_group_id = "sg-xxxxxxxx"
    }
    port2 = {
      vswitch_ids = {
        ap-northeast-1a = "vsw-sync-a"
      }
      security_group_id = "sg-xxxxxxxx"
    }
  }
  ha_sync_interface = "port2"
}
```

`ha_sync_interface` selects the interface for HA synchronization between FortiGate instances. It defaults to `port2` when multiple interfaces are defined. Configure FortiGate routes and policies to assign other traffic to the appropriate interfaces. Multiple interfaces require `function_compute.deploy_function = true` so Function Compute can create and attach the secondary ENIs.

## Network Interfaces Configuration

The `network.interfaces` map defines consecutive FortiGate interfaces from `port1` through `portN`.

The following example configures two interfaces. For a single interface, remove `port2` and omit `ha_sync_interface`.

```hcl
network = {
  interfaces = {
    port1 = {
      vswitch_ids = {
        ap-northeast-1a = "vsw-inspection-a"
        ap-northeast-1c = "vsw-inspection-c"
      }
      security_group_id = "sg-xxxxxxxx"
      route_cidrs       = ["192.168.0.0/24", "192.168.10.0/24"]
    }
    port2 = {
      vswitch_ids = {
        ap-northeast-1a = "vsw-sync-a"
        ap-northeast-1c = "vsw-sync-c"
      }
      security_group_id = "sg-xxxxxxxx"
      route_cidrs       = ["192.168.4.0/24", "192.168.14.0/24"]
    }
  }
  internet_bandwidth = 10
  ha_sync_interface  = "port2"
}
```

The interface count is determined by the entries in `network.interfaces`.

| Setting | Single interface | Multiple interfaces |
|---------|------------------|---------------------|
| `network.interfaces` | Define only `port1`. Inspection, management, and HA synchronization traffic share this interface. | Define `port1` and consecutive secondary interfaces, such as `port2` and `port3`. |
| `network.ha_sync_interface` | Omit it, leave it empty, or set it to `"port1"`. The default is `port1`. | Omit it or leave it empty to use `port2`, or specify another configured interface. |
| `function_compute.deploy_function` | Defaults to `true` for autoscale lifecycle handling and licensing. Disable it only when another system manages FortiGate autoscale. | Must be `true` because Function Compute creates and attaches the secondary ENIs. |

Each entry in `network.interfaces` uses the same parameters:

- `vswitch_ids` is a required `map(string)` mapping each zone ID to the VSwitch ID used by that interface. Provide at least one mapping. All interfaces must define the same set of zone IDs, with each VSwitch located in its specified zone.
- `security_group_id` is a required `string` specifying the security group attached to that interface's ENI.
- `route_cidrs` is an optional `list(string)` of destination networks for static routes inside FortiGate. The default is `[]`.

When a FortiGate instance launches, the scaling configuration creates its primary ENI (`port1`). Function Compute creates and attaches any secondary ENIs (`port2` through `portN`).

`network.internet_bandwidth` applies to both configurations and controls public IP allocation for each FortiGate instance. The default, `0`, assigns no public IP. A positive value assigns a public IP to `port1` and sets the maximum outbound internet bandwidth in Mbps. The example value, `10`, sets a limit of 10 Mbps.

## Function Behavior

Function Compute performs the following work:

- Maintains the Tablestore database for primary election, configuration updates, and instance deletion.
- Maintains a primary FortiGate and elects a replacement if the current primary fails.
- Creates and deletes secondary ENIs when multiple FortiGate interfaces are configured.
- Uploads configuration and licenses to FortiGate during startup.

The function role includes the required ECS ENI, ESS lifecycle, OSS, MNS, logging, and Tablestore transaction permissions.
