# CUE Patterns in KubeVela ComponentDefinitions

This document shows practical CUE patterns used in the `azure-vm` ComponentDefinition.

## Pattern 1: Mappings (Dictionaries)

**Use Case**: Map user-friendly names to technical values

```cue
// Define mapping
_sizeMap: {
  small:  "Standard_B2s"
  medium: "Standard_D2s_v3"
  large:  "Standard_D4s_v3"
}

// Use mapping
output: {
  spec: {
    hardwareProfile: {
      vmSize: _sizeMap[parameter.vmSize]  // Access by key
    }
  }
}
```

**User sees**: `vmSize: "small"`  
**Azure gets**: `"Standard_B2s"`

---

## Pattern 2: Nested Mappings

**Use Case**: Different mappings per environment

```cue
_envSizeMap: {
  dev: {
    small:  "Standard_B1s"   // Cheaper for dev
    medium: "Standard_B2s"
    large:  "Standard_D2s_v3"
  }
  prod: {
    small:  "Standard_D2s_v3" // No B-series in prod
    medium: "Standard_D4s_v3"
    large:  "Standard_D8s_v3"
  }
}

// Access nested value
vmSize: _envSizeMap[parameter.environment][parameter.vmSize]
```

---

## Pattern 3: Conditionals

**Use Case**: Different logic based on user input

```cue
// Conditional field assignment
_selectedVmSize: string
if parameter.environment != _|_ {
  // Has environment - use env-aware mapping
  _selectedVmSize: _envSizeMap[parameter.environment][parameter.vmSize]
}
if parameter.environment == _|_ {
  // No environment - use simple mapping
  _selectedVmSize: _sizeMap[parameter.vmSize]
}
```

**`_|_` means "undefined"** - checks if field exists

---

## Pattern 4: Conditional Resource Creation

**Use Case**: Only create public IP if enabled

```cue
// Main resource always created
output: {
  kind: "VirtualMachine"
  // ...
}

// Optional resource - only if publicIP.enabled == true
if parameter.publicIP.enabled {
  outputs: publicip: {
    kind: "PublicIPAddress"
    // ...
  }
}
```

---

## Pattern 5: Loops (Comprehensions)

**Use Case**: Merge user tags with platform defaults

```cue
_computedTags: {
  // Platform defaults
  ManagedBy: "kubevela"
  Environment: parameter.environment | *"unknown"
  
  // Loop through user tags and add them
  for k, v in parameter.tags {
    "\(k)": v  // String interpolation for dynamic keys
  }
}

output: {
  spec: {
    tags: _computedTags
  }
}
```

**Result**:
```
User provides: {Project: "my-app"}
Output gets:   {ManagedBy: "kubevela", Environment: "dev", Project: "my-app"}
```

---

## Pattern 6: List Comprehensions

**Use Case**: Generate multiple similar resources

```cue
parameter: {
  dataDisks: [...{
    name: string
    sizeGB: int
  }]
}

// Generate data disk attachments
output: {
  spec: {
    storageProfile: {
      dataDisks: [
        for i, disk in parameter.dataDisks {
          lun: i
          name: disk.name
          diskSizeGB: disk.sizeGB
          createOption: "Empty"
        }
      ]
    }
  }
}
```

---

## Pattern 7: String Interpolation

**Use Case**: Build ARMIds dynamically

```cue
owner: {
  armId: "/subscriptions/\(parameter.subscriptionId)/resourceGroups/\(parameter.resourceGroup)"
}

// Or multiline
_subnetArmId: """
  /subscriptions/\(parameter.subscriptionId)\
  /resourceGroups/\(parameter.network.vnetResourceGroup)\
  /providers/Microsoft.Network/virtualNetworks/\(parameter.network.vnetName)\
  /subnets/\(parameter.network.subnetName)
  """
```

---

## Pattern 8: Validation with Constraints

**Use Case**: Enforce naming conventions and limits

```cue
parameter: {
  resourceGroup: string & =~"^rg-.*"              // Must start with "rg-"
  vmName:        string & =~"^[a-z0-9-]{3,64}$"  // Alphanumeric, 3-64 chars
  osDiskSizeGB:  int & >=30 & <=1024             // Between 30-1024 GB
  vmSize:        "small" | "medium" | "large"    // Only these values allowed
}
```

---

## Pattern 9: Defaults and Optional Fields

**Use Case**: Provide sensible defaults

```cue
parameter: {
  // Optional with default
  location: *"eastus" | string
  
  // Optional field (may not be provided)
  environment?: "dev" | "prod"
  
  // Nested defaults
  adminPasswordSecret: {
    name: string | *"vm-admin-password"  // Default if not provided
    key:  string | *"password"
  }
  
  // Optional complex field
  tags?: {
    [string]: string
  }
}
```

---

## Pattern 10: Hidden Fields (Internal Variables)

**Use Case**: Intermediate calculations

```cue
// Hidden field (starts with _)
_selectedSize: _sizeMap[parameter.vmSize]

// Hidden computed values
_nicName: parameter.vmName + "-nic"
_pipName: parameter.vmName + "-pip"

// Use in output
output: {
  spec: {
    hardwareProfile: vmSize: _selectedSize
    networkProfile: {
      networkInterfaces: [{
        reference: name: _nicName
      }]
    }
  }
}
```

---

## Complete Example: User Application

```yaml
# What user writes (simple!)
apiVersion: core.oam.dev/v1beta1
kind: Application
metadata:
  name: my-app-vm
spec:
  components:
    - name: backend-vm
      type: azure-vm
      properties:
        vmName: "my-backend"
        vmSize: "medium"              # User-friendly!
        environment: "prod"            # Affects actual SKU
        resourceGroup: "rg-my-app"
        network:
          vnetName: "vn-prod"
          subnetName: "sn-apps"
        tags:
          Team: "backend"              # Merged with platform tags
```

## What KubeVela Generates (complex!)

```yaml
# VirtualMachine with:
# - vmSize: "Standard_D4s_v3" (from prod/medium mapping)
# - tags: {ManagedBy: kubevela, Environment: prod, Team: backend}
# - networkInterface reference to auto-generated NIC
# - No public IP (default policy)
```

---

## Summary: CUE Power in ComponentDefinitions

| Pattern | Use Case | Benefit |
|---------|----------|---------|
| Mappings | Simplify user inputs | Hide complexity |
| Conditionals | Environment-aware logic | Single definition, multiple behaviors |
| Loops | Generate repeated structures | DRY principle |
| Validation | Enforce policies | Prevent mistakes at submit time |
| Defaults | Reduce boilerplate | Users only specify what matters |
| Hidden fields | Intermediate calculations | Keep output clean |

**All of this happens in the YAML ComponentDefinition** - no separate tooling needed!
